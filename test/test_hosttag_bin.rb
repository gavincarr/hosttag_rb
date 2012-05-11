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
    [ 'centos',                 'aud001 nzd001 nzd002' ],
    [ 'laptop',                 'nzd002' ],
    [ 'vps',                    'nzd001' ],
    [ 'laptop vps',             '' ],
    [ '-a laptop vps',          '' ],
    [ '-o laptop vps',          'nzd001 nzd002' ],
    [ '-t nzd002',              'centos centos5 centos5-i386 laptop' ],
    [ '-t aud001',              'centos centos5 centos5-x86_64 public' ],
    [ '-t nzd001',              'centos centos4 centos4-x86_64 public vps' ],
    [ '-t aud001 nzd002',       'centos centos5 centos5-i386 centos5-x86_64 laptop public' ],
    [ '-to aud001 nzd002',      'centos centos5 centos5-i386 centos5-x86_64 laptop public' ],
    [ '-t -o aud001 nzd002',    'centos centos5 centos5-i386 centos5-x86_64 laptop public' ],
    [ '-ta aud001 nzd002',      'centos centos5' ],
    [ '-t -a aud001 nzd002',    'centos centos5' ],
    [ '-t -a aud001 nzd002 nzd001',  'centos' ],
    [ '-1 centos',              "aud001\nnzd001\nnzd002" ],
    [ '-o -1 laptop vps',       "nzd001\nnzd002" ],
    # List mode
    [ '-l centos5',             'centos5: aud001 nzd002' ],
    # All cases
    [ '-A',                     'aud001 nzd001 nzd002' ],
    [ '-A -A',                  'aud001 gbp004 nzd001 nzd002 usd003' ],
    [ '-T',                     'centos centos4 centos4-x86_64 centos5 centos5-i386 centos5-x86_64 laptop public vps' ],
    [ '-A -1',                  "aud001\nnzd001\nnzd002" ],
    [ '-A -1 -A',               "aud001\ngbp004\nnzd001\nnzd002\nusd003" ],
    [ '-1 -T',                  "centos\ncentos4\ncentos4-x86_64\ncentos5\ncentos5-i386\ncentos5-x86_64\nlaptop\npublic\nvps" ],
    # Try unrecognised tags as hosts
    [ 'nzd002',                 'centos centos5 centos5-i386 laptop' ],
    [ 'aud001 nzd002',          'centos centos5 centos5-i386 centos5-x86_64 laptop public' ],
    # Invalid data
    [ 'foo',                    %r{ \btag\b  .* not\sfound }x ],
    [ 'centos foo',             %r{ \btag\b  .* not\sfound }x ],
    [ '-t foo',                 %r{ \bhost\b .* not\sfound }x ],
    [ '-t n foo',               %r{ \bhost\b .* not\sfound }x ],
    # search globbing tests
    [ 'centos5-*',              'aud001 nzd002' ],
    [ 'vps centos5-*',          '' ],
    [ '-o vps centos5-*',       'aud001 nzd001 nzd002' ],
    [ '*ublic',                 'aud001 nzd001' ],
    [ '*4-*',                   'nzd001' ],
    [ '*-*',                    'aud001 nzd001 nzd002' ],
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

