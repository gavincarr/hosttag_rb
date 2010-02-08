#!/usr/bin/ruby

require 'test/unit'
require 'ftools'

class TestHosttag < Test::Unit::TestCase

  TESTS = [
    [ 'centos',                 'a m n' ],
    [ 'laptop',                 'n' ],
    [ 'vps',                    'm' ],
    [ 'laptop vps',             '' ],
    [ '-a laptop vps',          '' ],
    [ '-o laptop vps',          'm n' ],
    [ '-t n',                   'centos centos5 centos5-i386 laptop' ],
    [ '-t a',                   'centos centos5 centos5-x86_64 public' ],
    [ '-t m',                   'centos centos4 centos4-x86_64 public vps' ],
    [ '-t a n',                 'centos centos5 centos5-i386 centos5-x86_64 laptop public' ],
    [ '-to a n',                'centos centos5 centos5-i386 centos5-x86_64 laptop public' ],
    [ '-t -o a n',              'centos centos5 centos5-i386 centos5-x86_64 laptop public' ],
    [ '-ta a n',                'centos centos5' ],
    [ '-t -a a n',              'centos centos5' ],
    [ '-t -a a n m',            'centos' ],
    # All cases
    [ '-A',                     'a m n' ],
    [ '-A -A',                  'a g h m n' ],
    [ '-T',                     'centos centos4 centos4-x86_64 centos5 centos5-i386 centos5-x86_64 laptop public vps' ],
    # Try unrecognised tags as hosts
    [ 'n',                      'centos centos5 centos5-i386 laptop' ],
    [ 'a n',                    'centos centos5 centos5-i386 centos5-x86_64 laptop public' ],
    # Invalid data
    [ 'foo',                    %r{ \btag\b  .* not\sfound }x ],
    [ 'centos foo',             %r{ \btag\b  .* not\sfound }x ],
    [ '-t foo',                 %r{ \bhost\b .* not\sfound }x ],
    [ '-t n foo',               %r{ \bhost\b .* not\sfound }x ],
  ]

  def test_hosttag
    test_args = '--server localhost --ns hosttag_testing'

    # Setup
    datadir = "#{File.dirname(__FILE__)}/data_hosttag"
    bindir = File.join(File.dirname(__FILE__), '..', 'bin')
    File.directory?(datadir) or throw "missing datadir #{datadir}"
    `#{bindir}/htimport #{test_args} --delete --datadir #{datadir}`
    `#{bindir}/htdump #{test_args}`

    TESTS.each do |args, expected|
      got = `#{bindir}/hosttag #{test_args} #{args}`.chomp
      if expected.is_a?(String)
        assert_equal(expected, got)
      elsif expected.is_a?(Regexp)
        assert_match(expected, got)
      end
    end
  end

end

