
require 'hosttag/server'
require 'set'

module Hosttag

  # Lookup the given tag(s), returning an array of hosts to which they apply.
  # If multiple tags are given, by default the list of hosts is those to
  # which ALL of the tags apply i.e. results are ANDed or intersected. To
  # change this, pass :rel => :or in the options hash.
  # The final argument may be an options hash, which accepts the following
  # keys:
  # - :rel - either :and or :or, specifying the relationship to use when
  #   interpreting the set of tags. :rel => :and returns the set of hosts to
  #   which ALL the given tags apply; :rel => :or returns the set of hosts
  #   to which ANY of the tags apply. Default: :rel => :and.
  # - :include_skip? - flag indicating whether to include hosts that have
  #   the SKIP tag set. Default: false i.e. omit hosts tagged with SKIP.
  def hosttag_lookup_tags(*args)
    options = args.last.is_a?(Hash) ? args.pop : {}
    return lookup_keys(args, options.merge({ :type => :tag }))
  end

  # Lookup the given host(s), returning an array of tags that apply to
  # them. If multiple hosts are given, by default the list of tags is
  # those applying to ANY of the given hosts i.e. the results are ORed or
  # unioned. To change this pass an explicit :rel => :and in the options
  # hash.
  # The final argument may be an options hash, which accepts the following
  # keys:
  # - :rel - either :and or :or, specifying the relationship to use when
  #   interpreting the set of hosts. :rel => :and returns the set of tags
  #   that apply to ALL the given hosts; :rel => :or returns the set of tags
  #   that apply to ANY of the given hosts. Default: :rel => :or.
  # - :include_skip? - flag indicating whether to include hosts that have
  #   the SKIP tag set. Default: false i.e. omit hosts tagged with SKIP.
  def hosttag_lookup_hosts(*args)
    options = args.last.is_a?(Hash) ? args.pop : {}
    return lookup_keys(args, options.merge({ :type => :host }))
  end

  # Lookup the given host(s) or tag(s), returning an array of tags or hosts,
  # as appropriate. If a :type option is not explicitly given, first tries
  # the lookup using hosttag_lookup_tags, and if that fails retries using
  # hosttag_lookup_hosts.
  # The final argument may be an options hash, which accepts the following
  # keys:
  # - :type - either :host or :tag, specifying how to interpret the given
  #   arguments: :type => :host specifies that the arguments are hosts, and
  #   that the resultset should be a list of tags; :type => :tag specifies
  #   that the arguments are tags, and the resultset should be a list of
  #   hosts. Required, no default.
  # - :rel - either :and or :or, specifying the relationship to use when
  #   interpreting the set of results. :rel => :and returns only results
  #   that have ALL of the given attributes i.e. the AND result set;
  #   :rel => :or returns results that have ANY of the given attributes
  #   i.e. the OR result set. Default: depends on :type - :and for :type
  #   => :host, and :or for :type => :tag.
  # - :include_skip? - flag indicating whether to include hosts that have
  #   the SKIP tag set. Default: false i.e. omit hosts tagged with SKIP.
  def hosttag_lookup(*args)
    options = args.last.is_a?(Hash) ? args.pop : {}
    return lookup_keys(args, options) if options[:type]

    begin
      return hosttag_lookup_tags(args, options)
    rescue => e
      begin
        return hosttag_lookup_hosts(args, options)
      rescue
        # If both lookups failed, re-raise original error
        raise e
      end
    end
  end

  # Return an array of all hosts
  # The final argument may be an options hash, which accepts the following
  # keys:
  # - :include_skip? - flag indicating whether to include hosts that have
  #   the SKIP tag set. Default: false i.e. omit hosts tagged with SKIP.
  def hosttag_all_hosts(options)
    r = hosttag_server(options)
    key = r.get_key(options[:include_skip?] ? 'all_hosts_full' : 'all_hosts')
    $stderr.puts "+ key: #{key}" if options[:debug]
    return r.smembers(key).sort
  end

  # Return an array of all tags
  # The final argument may be an options hash, which accepts the following
  # keys:
  # - :include_skip? - flag indicating whether to include the SKIP tag.
  #   Default: false. Included for completeness.
  def hosttag_all_tags(options)
    r = hosttag_server(options)
    key = r.get_key(options[:include_skip?] ? 'all_tags_full' : 'all_tags')
    $stderr.puts "+ key: #{key}" if options[:debug]
    return r.smembers(key).sort
  end

  # Add the given tags to all the given hosts
  def hosttag_add_tags(hosts, tags, options)
    r = hosttag_server(options)

    tags_meta = extract_namespaces_from_tags( tags ) 

    # Add tags to each host
    skip_host = {}
    all_hosts_skip_hosts = true
    hosts.each do |host|
      host_meta = host + "_meta"

      key = r.get_key('host', host)
      tags.each { |tag| r.sadd(key, tag) }
      key_meta = r.get_key('host', host_meta)
      tags_meta.each { |tag| r.sadd(key_meta, tag) }

      if r.sismember(key, 'SKIP')
        skip_host[host] = true
      else
        all_hosts_skip_hosts = false
      end

      # Add to all_hosts sets
      all_hosts = r.get_key('all_hosts')
      all_hosts_full = r.get_key('all_hosts_full')
      # all_hosts shouldn't include SKIP hosts, so those we remove
      if skip_host[host]
        r.srem(all_hosts, host)
        r.srem(all_hosts, host_meta)
      else
        r.sadd(all_hosts, host)
        r.sadd(all_hosts, host_meta)
      end
      r.sadd(all_hosts_full, host)
      r.sadd(all_hosts_full, host_meta)
    end

    # Add hosts to each tag
    recheck_for_skip = false
    tags_total = tags + tags_meta
    tags_total.each do |tag|
      # If we've added a SKIP tag to these hosts, flag to do some extra work
      recheck_for_skip = true if tag == 'SKIP'

      key = r.get_key('tag', tag)
      hosts.each do |host|
        host_meta = host + "_meta"
        # The standard case is to add the host to the list for this tag.
        # But we don't want SKIP hosts being included in these lists, so
        # for them we actually do a remove to make sure they're omitted.
        if skip_host[host] and tag != 'SKIP'
          r.srem(key, host)
        else
          r.sadd(key, host) if tags.include? tag
          r.sadd(key, host_meta) if tags_meta.include tag
        end
      end

      # Add to all_tags sets
      all_tags = r.get_key('all_tags')
      all_tags_full = r.get_key('all_tags_full')
      r.sadd(all_tags, tag) unless all_hosts_skip_hosts
      r.sadd(all_tags_full, tag)
    end

    # If we've added a SKIP tag here, we need to recheck all tags for all skip hosts
    recheck_skip_change_for_all_tags(skip_host.keys, :add, r) if recheck_for_skip
  end

  # Delete the given tags from all the given hosts
  def hosttag_delete_tags(hosts, tags, options)
    r = hosttag_server(options)

    tags_meta = extract_namespaces_from_tags( tags )

    # Delete tags from each host
    non_skip_host = {}
    hosts.each do |host|
      key = r.get_key('host', host)
      tags.each { |tag| r.srem(key, tag) }

      if r.sismember(key, 'SKIP')
        skip_host = true
      else
        non_skip_host[host] = true
      end

      # Delete from all_hosts sets
      all_hosts = r.get_key('all_hosts')
      all_hosts_full = r.get_key('all_hosts_full')
      # If all tags have been deleted, or this is a SKIP host, remove from all_hosts
      if r.scard(key) == 0 or skip_host
        r.srem(all_hosts, host)
      else
        # NB: we explicitly add here in case we've deleted a SKIP tag
        r.sadd(all_hosts, host)
      end
      if r.scard(key) == 0
        r.srem(all_hosts_full, host)
        r.del(key)
      end
    end

    # Delete hosts from each tag
    recheck_for_skip = false
    all_tags = r.get_key('all_tags')
    all_tags_full = r.get_key('all_tags_full')
    tags.each do |tag|
      # If we've deleted a SKIP tag from these hosts, flag to do some extra work
      recheck_for_skip = true if tag == 'SKIP'

      tag_key = r.get_key('tag', tag)
      hosts.each { |host| r.srem(tag_key, host) }

      # Delete from all_tags sets
      # If all hosts have been deleted (or this is the SKIP tag), remove from all_tags
      if r.scard(tag_key) == 0 or tag == 'SKIP'
        r.srem(all_tags, tag)
      else
        # NB: we explicitly add here in case we've deleted a SKIP tag
        r.sadd(all_tags, tag)
      end
      if r.scard(tag_key) == 0
        r.srem(all_tags_full, tag)
        r.del(tag_key)
      end
    end
    r.del(all_tags) if r.scard(all_tags) == 0
    r.del(all_tags_full) if r.scard(all_tags_full) == 0

    # If we've deleted a SKIP tag here, we need to recheck all tags for all non-skip hosts
    recheck_skip_change_for_all_tags(non_skip_host.keys, :delete, r) if recheck_for_skip
  end

  # Delete all hosts and tags in the hosttag datastore. This is the nuclear option,
  # used in hosttag_import_from_directory if :delete => true. Interactively confirms
  # unless the :autoconfirm option is set.
  # The final argument may be an options hash, which accepts the following
  # keys:
  # - :autoconfirm - if true, truncate without asking for any confirmation
  def hosttag_truncate(options)
    if not options[:autoconfirm]
      print "Do you really want to delete EVERYTHING from your datastore? [yN] "
      $stdout.flush
      confirm = $stdin.gets.chomp
      return unless confirm =~ %r{^y}i
    end

    r = hosttag_server(options)
    r.keys(r.get_key("*")).each { |k| r.del(k) }
  end

  # Delete all tags from the given hosts. Interactively confirms the deletions
  # unless the :autoconfirm option is set.
  # The final argument may be an options hash, which accepts the following
  # keys:
  # - :autoconfirm - if true, do deletes without asking for any confirmation
  def hosttag_delete_all_tags(hosts, options)
    if not options[:autoconfirm]
      host_str = hosts.join(' ')
      print "Do you want to delete all tags on the following host(s):\n  #{host_str}\nConfirm? [yN] "
      $stdout.flush
      confirm = $stdin.gets.chomp
      return unless confirm =~ %r{^y}i
    end

    hosts.each do |host|
      begin
        tags = hosttag_lookup_hosts(host, options)
        hosttag_delete_tags([ host ], tags, options)
      rescue
        warn "Warning: invalid host '#{host}' - cannot delete"
      end
    end
  end

  # Import hosts and tags from the given directory. The directory is
  # expected to contain a set of directories, representing hosts; each
  # file within those directories is treated as a tag that applies to
  # that host.
  # Options is a hash which accepts the following keys:
  # - :delete - if true, delete ALL hosts and tags from the datastore
  #   before doing the import.
  # - :autoconfirm - if true, don't interactively confirm deletions
  def hosttag_import_from_directory(datadir, options)
    # Delete ALL hosts and tags from the datastore if options[:delete] set
    hosttag_truncate(options) if options[:delete]

    # Load directory into a { host => [ taglist ] } hash
    host_tag_hash = load_directory(datadir, options)

    # Add all hosts and tags
    host_tag_hash.each do |host, tags|
      hosttag_add_tags([ host ], tags, options)
    end
  end

  private

  # Lookup the given keys in the redis datastore, returning an array of
  # results. If more than one key is specified, resultsets are merged
  # (either ANDed or ORed) depending on the value of the :rel option.
  # The final argument must be an options hash, which accepts the
  # following options:
  # - :type - specifies the type of keys to lookup, either :host or :tag.
  #   Required.
  # - :rel - specifies how to merge multiple resultsets, either :and (set
  #   intersection) or :or (set union).
  def lookup_keys(*args)
    options = args.last.is_a?(Hash) ? args.pop : {}
    args.flatten!

    type = options[:type]
    throw "Required option 'type' missing" if not type
    rel = options[:rel]

    r = hosttag_server(options)

    # Default a rel if we have multiple args
    if args.length > 1 and not rel
      rel = (type == :tag ? :and : :or)
    end
    $stderr.puts "+ rel (#{type}): #{rel}" if rel and options[:debug]

    # Map keys to fetch
    keys = args.collect {|v| r.get_key(type, v) }
    $stderr.puts "+ keys: #{keys.join(' ')}" if options[:debug]

    # Check all keys exist
    keys.each do |k|
      if not r.exists(k)
        item = k.sub(%r{^[^:]+::[^:]+:}, '')
        raise "Error: #{type} '#{item}' not found."
      end
    end

    # Lookup and return
    if keys.length == 1
      r.smembers(keys[0]).sort
    elsif rel == :and
      r.sinter(*keys).sort
    else
      r.sunion(*keys).sort
    end
  end

  # for a given set of tags extract out a list of all the 
  # namespaces for use in the metadata host data set.
  # Eg: tags=["centos","test::sydney::dc1::rack2","prod::sydney::dc2::rack4"]
  # we will return an array consisting of the namespaces.
  # EG: res=["test::sydney::dc1","test::sydney","test::","sydney::dc1::rack2",
  # "sydney::dc1","sydney::","rack2::","prod::sydney::dc2","prod::sydney",
  # "sydney::dc2::rack4","sydney::dc2","sydney::","dc2::rack4","rack4::"]
  # These tags will not show up in normal results BUT you can search on them 
  # to get lists of hosts, for example ht sydney::dc2 will return a list of 
  # all hosts in sydney and dc2.
  def extract_namespaces_from_tags( tags )
    result = []
    tags.each do |t|
      next unless  t.include? "::"

      a = t.split("::")
      
      until a.empty?  do
        first = a.shift
        c = Array.new a

        result << first + "::"
        c.each do |cc|
          element = result.last + "::" + cc
          element.gsub!(/::::/, '::')
          result << element unless tags.include? element
        end
      end
    end
    result.to_set.to_a # return unique elements (.uniq() does not work here)
  end


  # If we've added or removed a SKIP tag, we now have to recheck all tags for
  # the given hosts, removing or re-adding them from/to those tag sets, and
  # then recalculate the all_tags set for each of those tags
  def recheck_skip_change_for_all_tags(hosts, change, r)
    recheck_tags = {}
    hosts.each do |host|
      host_key = r.get_key('host', host)
      r.smembers(host_key).each do |tag|
        next if tag == 'SKIP'

        tag_key = r.get_key('tag', tag)
        # If we've added SKIP tags, then we remove the host from tagsets
        # (or vice-versa)
        if change == :add
          r.srem(tag_key, host)
        else
          r.sadd(tag_key, host)
        end

        recheck_tags[tag] = tag_key
      end
    end

    # Now recheck the all_tags set, adding tags that have hosts, and
    # removing any that don't
    all_tags = r.get_key('all_tags')
    recheck_tags.each do |tag, tag_key|
      tag_host_count = r.scard(tag_key)
      if tag_host_count == 0
        r.srem(all_tags, tag)
      else
        r.sadd(all_tags, tag)
      end
    end
    r.del(all_tags) if r.scard(all_tags) == 0
  end

  # Load all host/tag files in datadir, returning a { host => [ taglist ] } hash
  def load_directory(datadir, options)
    host_tag_hash = {}

    Dir.glob("#{datadir}/*").each do |host_path|
      next if not File.directory?(host_path)
      host = host_path.sub(/^#{datadir}\//, '')

      host_tag_hash[host] = []
      Dir.glob("#{host_path}/*").each do |tag_path|
        next if not File.file?(tag_path)
        tag = File.basename(tag_path)
        host_tag_hash[host].push(tag)
      end
    end

    return host_tag_hash
  end

  def die(error)
    warn error
    exit 1
  end

  def hosttag_server(options)
    begin
      r = Hosttag::Server.new(options)
    rescue Resolv::ResolvError => e
      die e
    end
  end

end
