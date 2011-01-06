
require 'hosttag/server'

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
    options[:type] = :tag
    return lookup_keys(args, options)
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
    options[:type] = :host
    return lookup_keys(args, options)
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
        # If both lookups failed, return original error
        warn e
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
    key = r.get_key('all_hosts')
    key += "_noskip" if not options[:include_skip?]
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
    key = r.get_key('all_tags')
    key += "_noskip" if not options[:include_skip?]
    $stderr.puts "+ key: #{key}" if options[:debug]
    return r.smembers(key).sort
  end

  # Add the given tags to all the given hosts
  def hosttag_add_tags(hosts, tags, options)
    r = hosttag_server(options)

    # Add tags to each host
    skip_host = {}
    all_hosts_skip_hosts = true
    hosts.each do |host|
      key = r.get_key('host', host)
      tags.each { |tag| r.sadd(key, tag) }

      if r.sismember(key, 'SKIP')
        skip_host[host] = true
      else
        all_hosts_skip_hosts = false
      end

      # Add to all_hosts sets
      all_hosts_noskip = r.get_key('all_hosts_noskip')
      all_hosts = r.get_key('all_hosts')
      # all_hosts_noskip shouldn't include SKIP hosts, so those we remove
      if skip_host[host]
        r.srem(all_hosts_noskip, host)
      else
        r.sadd(all_hosts_noskip, host)
      end
      r.sadd(all_hosts, host)
    end

    # Add hosts to each tag
    recheck_for_skip = false
    tags.each do |tag|
      # If we've added a SKIP tag to these hosts, flag to do some extra work
      recheck_for_skip = true if tag == 'SKIP'

      key = r.get_key('tag', tag)
      hosts.each do |host|
        # The standard case is to add the host to the list for this tag.
        # But we don't want SKIP hosts being included in these lists, so
        # for them we actually do a remove to make sure they're omitted.
        if skip_host[host] and tag != 'SKIP'
          r.srem(key, host)
        else
          r.sadd(key, host)
        end
      end

      # Add to all_tags sets
      all_tags_noskip = r.get_key('all_tags_noskip')
      all_tags = r.get_key('all_tags')
      r.sadd(all_tags_noskip, tag) unless all_hosts_skip_hosts
      r.sadd(all_tags, tag)
    end

    # If we've added a SKIP tag here, we need to recheck all tags for all skip hosts
    recheck_skip_change_for_all_tags(skip_host.keys, :add, r) if recheck_for_skip
  end

  # Delete the given tags from all the given hosts
  def hosttag_delete_tags(hosts, tags, options)
    r = hosttag_server(options)

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
      all_hosts_noskip = r.get_key('all_hosts_noskip')
      all_hosts = r.get_key('all_hosts')
      # If all tags have been deleted, or this is a SKIP host, remove from all_hosts_noskip
      if r.scard(key) == 0 or skip_host
        r.srem(all_hosts_noskip, host)
      else
        # NB: we explicitly add here in case we've deleted a SKIP tag
        r.sadd(all_hosts_noskip, host)
      end
      if r.scard(key) == 0
        r.srem(all_hosts, host)
        r.del(key)
      end
    end

    # Delete hosts from each tag
    recheck_for_skip = false
    tags.each do |tag|
      # If we've deleted a SKIP tag from these hosts, flag to do some extra work
      recheck_for_skip = true if tag == 'SKIP'

      tag_key = r.get_key('tag', tag)
      hosts.each { |host| r.srem(tag_key, host) }

      # Delete from all_tags sets
      all_tags_noskip = r.get_key('all_tags_noskip')
      all_tags = r.get_key('all_tags')
      # If all hosts have been deleted (or this is the SKIP tag), remove from all_tags_noskip
      if r.scard(tag_key) == 0 or tag == 'SKIP'
        r.srem(all_tags_noskip, tag)
      else
        # NB: we explicitly add here in case we've deleted a SKIP tag
        r.sadd(all_tags_noskip, tag)
      end
      if r.scard(tag_key) == 0
        r.srem(all_tags, tag)
        r.del(tag_key)
      end
    end

    # If we've deleted a SKIP tag here, we need to recheck all tags for all non-skip hosts
    recheck_skip_change_for_all_tags(non_skip_host.keys, :delete, r) if recheck_for_skip
  end

  # Delete all tags from the given hosts. Interactively confirms the deletion
  # for each host, unless the :autoconfirm option is set.
  # The final argument may be an options hash, which accepts the following
  # keys:
  # - :autoconfirm - if true, don't interactively confirm deletions
  def hosttag_delete_all_tags(hosts, options)
    hosts.each do |host|
      begin
        tags = hosttag_lookup_hosts(host, options)
        if not options[:autoconfirm]
          print "Delete all tags on host '#{host}'? [yN] "
          $stdout.flush
          confirm = $stdin.gets.chomp
        end
        if options[:autoconfirm] or confirm =~ %r{^y}i
          hosttag_delete_tags([ host ], tags, options)
        end
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
    if options[:delete]
      hosts_all = hosttag_all_hosts(options.merge({ :include_skip? => true }))
      hosttag_delete_all_tags(hosts_all, options)
    end

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
      r.smembers(keys).sort
    elsif rel == :and
      r.sinter(*keys).sort
    else
      r.sunion(*keys).sort
    end
  end

  # If we've added or removed a SKIP tag, we now have to recheck all tags for
  # the given hosts, removing or re-adding them from/to those tag sets, and
  # then recalculate the all_tags_noskip set for each of those tags
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

    # Now recheck the all_tags_noskip set, adding tags that have hosts, and
    # removing any that don't
    all_tags_noskip = r.get_key('all_tags_noskip')
    recheck_tags.each do |tag, tag_key|
      tag_host_count = r.scard(tag_key)
      if tag_host_count == 0
        r.srem(all_tags_noskip, tag)
      else
        r.sadd(all_tags_noskip, tag)
      end
    end
  end

  # Load all host/tag files in datadir, returning a { host => [ taglist ] } hash
  def load_directory(datadir, options)
    host_tag_hash = {}

    Dir.chdir(datadir)
    Dir.glob("*").each do |host|
      next if not File.directory?(host)

      host_tag_hash[host] = []
      Dir.glob("#{host}/*").each do |tag_path|
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
