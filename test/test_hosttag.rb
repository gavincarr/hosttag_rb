#!/usr/bin/ruby

require 'test/unit'

class TestHostTag < Test::Unit::TestCase

  TESTS = [
    [ 'centos',             'axe mattock nox' ],
    [ 'laptop',             'nox' ],
    [ 'vps',                'mattock' ],
    [ 'laptop vps',         '' ],
    [ '-a laptop vps',      '' ],
    [ '-o laptop vps',      'mattock nox' ],
    [ '-t nox',             'centos centos5 centos5-i386 laptop' ],
    [ '-t axe',             'centos centos5 centos5-x86_64 public' ],
    [ '-t mattock',         'centos centos4 centos4-x86_64 public vps' ],
    [ '-t axe nox',         'centos centos5 centos5-i386 centos5-x86_64 laptop public' ],
    [ '-to axe nox',        'centos centos5 centos5-i386 centos5-x86_64 laptop public' ],
    [ '-t -o axe nox',      'centos centos5 centos5-i386 centos5-x86_64 laptop public' ],
    [ '-ta axe nox',        'centos centos5' ],
    [ '-t -a axe nox',      'centos centos5' ],
    [ '-t -a axe nox mattock',  'centos' ],
    [ '-A',                 'axe mattock nox' ],
    [ '-A -A',              'axe granite hammer mattock nox' ],
    [ '-T',                 'centos centos4 centos4-x86_64 centos5 centos5-i386 centos5-x86_64 laptop public vps' ],
  ]

  def test_hosttag
    TESTS.each do |args, expected|
      got = `../bin/hosttag.rb #{args}`.chomp
      assert_equal(expected, got)
    end
  end

end

