
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
    return lookup(args, options)
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
    return lookup(args, options)
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
    return lookup(args, options) if options[:type]

    begin
      return hosttag_lookup_tags(args, options)
    rescue
      return hosttag_lookup_hosts(args, options)
    end
  end

  # Return an array of all tags
  # The final argument may be an options hash, which accepts the following 
  # keys:
  # - :include_skip? - flag indicating whether to include hosts that have
  #   the SKIP tag set. Default: false i.e. omit hosts tagged with SKIP.
  def hosttag_all_tags(options)
    key = r.get_key(:tag)
    key += "_noskip" if options[:include_skip?]
    $stderr.puts "+ key: #{key}" if options[:debug]
    return r.smembers(key).sort
  end

  # Return an array of all hosts
  # The final argument may be an options hash, which accepts the following 
  # keys:
  # - :include_skip? - flag indicating whether to include hosts that have
  #   the SKIP tag set. Default: false i.e. omit hosts tagged with SKIP.
  def hosttag_all_hosts(options)
    key = r.get_key(:host)
    key += "_noskip" if options[:include_skip?]
    $stderr.puts "+ key: #{key}" if options[:debug]
    return r.smembers(key).sort
  end

  private

  def lookup(*args)
    options = args.last.is_a?(Hash) ? args.pop : {}
    args.flatten!

    type            = options[:type] 
    throw "Required option 'type' missing" if not type
    rel             = options[:rel]

    r               = hosttag_server(options)

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
      r.smembers( keys ).sort
    elsif rel == :and
      r.sinter( *keys ).sort
    else
      r.sunion( *keys ).sort
    end
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
