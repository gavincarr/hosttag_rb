#!/usr/bin/ruby

require 'test/unit'
require 'fileutils'

require 'hosttag'
include Hosttag

class TestHtsetLib < Test::Unit::TestCase

  def setup
    @test_args = '--server localhost --ns hosttag_testing'
    @test_opts = { :server => 'localhost', :namespace => 'hosttag_testing',
      :delete => true, :autoconfirm => true, :debug => false }
    datadir = "#{File.dirname(__FILE__)}/data_reset"
    @bindir = File.join(File.dirname(__FILE__), '..', 'bin')
    File.directory?(datadir) or throw "missing datadir #{datadir}"
    hosttag_import_from_directory(datadir, @test_opts)
  end

  # -----------------------------------------------------------------------
  # Testing hosttag_add_tags and hosttag_delete_tags
  # -----------------------------------------------------------------------

  TESTS = [
    [
      %w{htset foo centos},         # operation
      %w{foo},                      # ht -A output
      %w{foo},                      # ht -A -A output
      %w{centos},                   # ht -T output
      %w{centos},                   # ht -T -T output
    ],
    [
      %w{htset foo centos5},
      %w{foo},
      %w{foo},
      %w{centos centos5},
      %w{centos centos5},
    ],
    [
      %w{htset bar centos},
      %w{bar foo},
      %w{bar foo},
      %w{centos centos5},
      %w{centos centos5},
    ],
    [
      %w{htset bar centos4},
      %w{bar foo},
      %w{bar foo},
      %w{centos centos4 centos5},
      %w{centos centos4 centos5},
    ],
    [
      %w{htset bar SKIP},
      %w{foo},
      %w{bar foo},
      %w{centos centos5},
      %w{SKIP centos centos4 centos5},
    ],
    [
      %w{htset bar centos4-i386},
      %w{foo},
      %w{bar foo},
      %w{centos centos5},
      %w{SKIP centos centos4 centos4-i386 centos5},
    ],
    [
      %w{htdel bar centos4},
      %w{foo},
      %w{bar foo},
      %w{centos centos5},
      %w{SKIP centos centos4-i386 centos5},
    ],
    [
      %w{htdel bar SKIP},
      %w{bar foo},
      %w{bar foo},
      %w{centos centos4-i386 centos5},
      %w{centos centos4-i386 centos5},
    ],
    [
      %w{htdel foo centos5},
      %w{bar foo},
      %w{bar foo},
      %w{centos centos4-i386},
      %w{centos centos4-i386},
    ],
    [
      %w{htdel foo centos},
      %w{bar},
      %w{bar},
      %w{centos centos4-i386},
      %w{centos centos4-i386},
    ],
    [
      %w{htdel bar centos},
      %w{bar},
      %w{bar},
      %w{centos4-i386},
      %w{centos4-i386},
    ],
    [
      %w{htdel bar centos4-i386},
      [],
      [],
      [],
      [],
    ],
  ]

  def test_hosttag_add_delete_tags
    TESTS.each do |op, all_hosts, all_hosts_full, all_tags, all_tags_full|
      cmd = op.join(' ')
      bin = op.shift()
      if bin == 'htset'
        hosttag_add_tags([ op[0] ], [ op[1] ], @test_opts)
      else
        hosttag_delete_tags([ op[0] ], [ op[1] ], @test_opts)
      end

      # Check results
      assert_equal(all_hosts, hosttag_all_hosts(@test_opts), "all_hosts, #{cmd}")
      assert_equal(all_hosts_full, hosttag_all_hosts(@test_opts.merge({ :include_skip? => true })),
        "all_hosts_full, #{cmd}")
      assert_equal(all_tags, hosttag_all_tags(@test_opts),  "all_tags, #{cmd}")
      assert_equal(all_tags_full, hosttag_all_tags(@test_opts.merge({ :include_skip? => true })),
        "all_tags_full, #{cmd}")
    end
  end

  # -----------------------------------------------------------------------
  # Testing hosttag_delete_all_tags
  # -----------------------------------------------------------------------

  # Format: host => tags
  SETUP2 = [
    %w{foo centos centos5 centos5-x86_64 dell},
    %w{bar ubuntu ubuntu-lucid hp},
    %w{cat debian debian4 dell},
    %w{dog fedora fedora14 supermicro},
  ]
  TESTS2 = [
    # Format: hosts to delete, ht -A output, ht -T output
    [
      %w{},
      %w{bar cat dog foo},
      %w{centos centos5 centos5-x86_64 debian debian4 dell fedora fedora14 hp supermicro ubuntu ubuntu-lucid},
    ],
    [
      %w{foo},
      %w{bar cat dog},
      %w{debian debian4 dell fedora fedora14 hp supermicro ubuntu ubuntu-lucid},
    ],
    [
      %w{cat dog},
      %w{bar},
      %w{hp ubuntu ubuntu-lucid},
    ],
    [
      %w{bar},
      %w{},
      %w{},
    ],
  ]

  def test_hosttag_delete_all_tags
    SETUP2.each do |host, *tags|
      hosttag_add_tags([ host ], tags, @test_opts)
    end
    TESTS2.each do |hosts, all_hosts, all_tags|
      if hosts.length > 0
        hosttag_delete_all_tags(hosts, @test_opts)
      end

      # Check results
      assert_equal(all_hosts, hosttag_all_hosts(@test_opts), "all_hosts after deleting #{hosts}")
      assert_equal(all_tags,  hosttag_all_tags(@test_opts),  "all_tags after deleting #{hosts}")
    end
  end

end

