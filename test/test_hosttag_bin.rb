#!/usr/bin/ruby

require 'test/unit'
require 'fileutils'

require 'hosttag'
include Hosttag

class TestHosttagBin < Test::Unit::TestCase
  def setup
    @test_args = '--server localhost --ns hosttag_testing'
    @test_opts = { :server => 'localhost', :namespace => 'hosttag_testing',
      :delete => true, :autoconfirm => true, :debug => false }
    @bindir = File.join(File.dirname(__FILE__), '..', 'bin')
    datadir = "#{File.dirname(__FILE__)}/data_hosttag"
    File.directory?(datadir) or throw "missing datadir #{datadir}"
    hosttag_import_from_directory(datadir, @test_opts)
  end

  # format: args (string) => expected (either string or regex)
  TESTS = [
    [ 'centos',                 'a m n' ],
    [ 'laptop',                 'n' ],
    [ 'vps',                    'm' ],
    [ 'laptop vps',             '' ],
    [ '-a laptop vps',          '' ],
    [ '-o laptop vps',          'm n' ],
    [ '-t n',                   'centos centos5 centos5-i386 laptop namespace2::dc1::rack2' ],
    [ '-t a',                   'centos centos5 centos5-x86_64 namespace1::test namespace2::dc1::rack2 namespace2::staging::engine public' ],
    [ '-t m',                   'centos centos4 centos4-x86_64 namespace2::dc1::rack1 namespace2::prod::engine public vps' ],
    [ '-t a n',                 'centos centos5 centos5-i386 centos5-x86_64 laptop namespace1::test namespace2::dc1::rack2 namespace2::staging::engine public' ],
    [ '-to a n',                'centos centos5 centos5-i386 centos5-x86_64 laptop namespace1::test namespace2::dc1::rack2 namespace2::staging::engine public' ],
    [ '-t -o a n',              'centos centos5 centos5-i386 centos5-x86_64 laptop namespace1::test namespace2::dc1::rack2 namespace2::staging::engine public' ],
    [ '-ta a n',                'centos centos5 namespace2::dc1::rack2' ],
    [ '-t -a a n',              'centos centos5 namespace2::dc1::rack2' ],
    [ '-t -a a n m',            'centos' ],
    [ '-1 centos',              "a\nm\nn" ],
    [ '-o -1 laptop vps',       "m\nn" ],
    # List mode
    [ '-l centos5',             'centos5: a n' ],
    # All cases
    [ '-A',                     'a m n' ],
    [ '-A -A',                  'a g h m n' ],
    [ '-T',                     'centos centos4 centos4-x86_64 centos5 centos5-i386 centos5-x86_64 laptop namespace1::test namespace2::dc1::rack1 namespace2::dc1::rack2 namespace2::prod::engine namespace2::staging::engine public vps' ],
    [ '-A -1',                  "a\nm\nn" ],
    [ '-A -1 -A',               "a\ng\nh\nm\nn" ],
    [ '-1 -T',                  "centos\ncentos4\ncentos4-x86_64\ncentos5\ncentos5-i386\ncentos5-x86_64\nlaptop\nnamespace1::test\nnamespace2::dc1::rack1\nnamespace2::dc1::rack2\nnamespace2::prod::engine\nnamespace2::staging::engine\npublic\nvps" ],
    # Try unrecognised tags as hosts
    [ 'n',                      'centos centos5 centos5-i386 laptop namespace2::dc1::rack2' ],
    [ 'a n',                    'centos centos5 centos5-i386 centos5-x86_64 laptop namespace1::test namespace2::dc1::rack2 namespace2::staging::engine public' ],
    # Invalid data
    [ 'foo',                    %r{ \btag\b  .* not\sfound }x ],
    [ 'centos foo',             %r{ \btag\b  .* not\sfound }x ],
    [ '-t foo',                 %r{ \bhost\b .* not\sfound }x ],
    [ '-t n foo',               %r{ \bhost\b .* not\sfound }x ],
    # special cases for hosts_meta
    [ 'n_meta',                 'dc1:: dc1::rack2 namespace2:: namespace2::dc1 rack2::' ],
  ]

  def test_hosttag
    TESTS.each do |args, expected|
      got = `#{@bindir}/hosttag #{@test_args} #{args} 2>&1`.chomp
      if expected.is_a?(String)
        assert_equal(expected, got, "args: #{args}")
      elsif expected.is_a?(Regexp)
        assert_match(expected, got, "args: #{args}")
      end
    end
  end

end

