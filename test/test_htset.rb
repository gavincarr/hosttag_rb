#!/usr/bin/ruby

require 'test/unit'
require 'ftools'

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

  def test_htset
    test_args = '--server localhost --ns hosttag_testing'

    # Setup
    datadir = "#{File.dirname(__FILE__)}/data_reset"
    bindir = File.join(File.dirname(__FILE__), '..', 'bin')
    File.directory?(datadir) or throw "missing datadir #{datadir}"
    `#{bindir}/htimport #{test_args} --delete --datadir #{datadir}`

    TESTS.each do |op, hosts1, hosts2, tags1|
      bin=op.shift()
      `#{bindir}/#{bin} #{test_args} #{op.join(' ')}`
      got=`#{bindir}/ht #{test_args} -A`.chomp
      assert_equal(hosts1.sort.join(' '), got)
      got=`#{bindir}/ht #{test_args} -A -A`.chomp
      assert_equal(hosts2.sort.join(' '), got)
      got=`#{bindir}/ht #{test_args} -T`.chomp
      assert_equal(tags1.sort.join(' '), got)
    end
  end
end

