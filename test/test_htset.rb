#!/usr/bin/ruby

require 'test/unit'
require 'ftools'

require 'hosttag'
include Hosttag

class TestHtset < Test::Unit::TestCase

  TESTS = [
    [ 
      [ 'htset', 'foo', 'centos' ],    # operation
      [ 'foo' ],                       # ht -A output
      [ 'foo' ],                       # ht -A -A output
      [ 'centos' ],                    # ht -T output
    ],
    [ 
      [ 'htset', 'foo', 'centos5' ],
      [ 'foo' ],
      [ 'foo' ],
      [ 'centos', 'centos5' ],
    ],
    [ 
      [ 'htset', 'bar', 'centos' ],
      [ 'bar', 'foo' ],
      [ 'bar', 'foo' ],
      [ 'centos', 'centos5' ],
    ],
    [ 
      [ 'htset', 'bar', 'centos4' ],
      [ 'bar', 'foo' ],
      [ 'bar', 'foo' ],
      [ 'centos', 'centos4', 'centos5' ],
    ],
    [ 
      [ 'htset', 'bar', 'SKIP' ],
      [ 'foo' ],
      [ 'bar', 'foo' ],
      [ 'centos', 'centos4', 'centos5' ],
    ],
    [ 
      [ 'htdel', 'bar', 'SKIP' ],
      [ 'bar', 'foo' ],
      [ 'bar', 'foo' ],
      [ 'centos', 'centos4', 'centos5' ],
    ],
    [ 
      [ 'htdel', 'bar', 'centos4' ],
      [ 'bar', 'foo' ],
      [ 'bar', 'foo' ],
      [ 'centos', 'centos5' ],
    ],
    [ 
      [ 'htdel', 'bar', 'centos' ],
      [ 'foo' ],
      [ 'foo' ],
      [ 'centos', 'centos5' ],
    ],
    [ 
      [ 'htdel', 'foo', 'centos' ],
      [ 'foo' ],
      [ 'foo' ],
      [ 'centos5' ],
    ],
    [ 
      [ 'htdel', 'foo', 'centos5' ],
      [],
      [],
      [],
    ],
  ]

  def setup
    @test_args = '--server localhost --ns hosttag_testing'
    @test_opts = { :server => 'localhost', :namespace => 'hosttag_testing', :debug => false }
    datadir = "#{File.dirname(__FILE__)}/data_reset"
    @bindir = File.join(File.dirname(__FILE__), '..', 'bin')
    File.directory?(datadir) or throw "missing datadir #{datadir}"
    `#{@bindir}/htimport #{@test_args} --delete --datadir #{datadir}`
  end

  def test_htset
    TESTS.each do |op, hosts1, hosts2, tags1|
      cmd = op.join(' ')
      bin = op.shift()
      `#{@bindir}/#{bin} #{@test_args} #{op.join(' ')}`

      # Check results
      assert_equal(hosts1, hosttag_all_hosts(@test_opts), "all_hosts, #{cmd}")
      assert_equal(hosts2, hosttag_all_hosts(@test_opts.merge({ :include_skip? => true })), 
        "all_hosts include_skip, #{cmd}")
      assert_equal(tags1, hosttag_all_tags(@test_opts),  "all_tags, #{cmd}")
    end
  end
end

