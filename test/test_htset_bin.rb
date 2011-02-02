#!/usr/bin/ruby

require 'test/unit'
require 'ftools'

require 'hosttag'
include Hosttag

class TestHtsetBin < Test::Unit::TestCase

  def setup
    @test_args = '--server localhost --ns hosttag_testing'
    @test_opts = { :server => 'localhost', :namespace => 'hosttag_testing',
      :delete => true, :autoconfirm => true, :debug => false }
    datadir = "#{File.dirname(__FILE__)}/data_reset"
    @bindir = File.join(File.dirname(__FILE__), '..', 'bin')
    File.directory?(datadir) or throw "missing datadir #{datadir}"
    hosttag_import_from_directory(datadir, @test_opts)
  end

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

  def test_htset
    TESTS.each do |op, all_hosts, all_hosts_full, all_tags, all_tags_full|
      cmd = op.join(' ')
      bin = op.shift()
      error = %x{#{@bindir}/#{bin} #{@test_args} #{op.join(' ')}}

      # Check results
      assert_equal("", error, "Error output found: #{error}")
      assert_equal(all_hosts, hosttag_all_hosts(@test_opts), "all_hosts, #{cmd}")
      assert_equal(all_hosts_full, hosttag_all_hosts(@test_opts.merge({ :include_skip? => true })),
        "all_hosts include_skip, #{cmd}")
      assert_equal(all_tags, hosttag_all_tags(@test_opts),  "all_tags, #{cmd}")
      assert_equal(all_tags_full, hosttag_all_tags(@test_opts.merge({ :include_skip? => true })),
        "all_tags_full, #{cmd}")
    end
  end

  # Test argument classification
  # Format: operation, error, all_hosts, all_tags
  CLASSIFY_TESTS = [
    [
      %w{htset foo centos},
      '',
      %w{foo},
      %w{centos},
    ],
    [
      %w{htset cat foo dog centos5},            # unclassifiable host (dog) should give gives error
      "Error: can't auto-classify 'dog' - aborting\n",
      %w{foo},
      %w{centos},
    ],
    [
      %w{htset cat dell centos centos5-x86_64}, # unclassifiable tag (dell) should give error
      "Error: can't auto-classify 'dell' - aborting\n",
      %w{foo},
      %w{centos},
    ],
    [
      %w{htset cat dog foo centos5},            # known host allows classification of former args as hosts
      '',
      %w{cat dog foo},
      %w{centos centos5},
    ],
    [
      %w{htset cat centos dell centos5-x86_64}, # known tag allows classification of later args as tags
      '',
      %w{cat dog foo},
      %w{centos centos5 centos5-x86_64 dell},
    ],
  ]

  def test_htset_argument_classification
    CLASSIFY_TESTS.each do |op, error, all_hosts, all_tags|
      cmd = op.join(' ')
      bin = op.shift()
      output = %x{#{@bindir}/#{bin} #{@test_args} #{op.join(' ')}}

      # Check results
      assert_equal(error, output, "Error output mismatch")
      assert_equal(all_hosts, hosttag_all_hosts(@test_opts), "all_hosts, #{cmd}")
      assert_equal(all_tags,  hosttag_all_tags(@test_opts),  "all_tags, #{cmd}")
    end
  end

end

