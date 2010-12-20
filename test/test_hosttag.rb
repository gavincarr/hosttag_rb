#!/usr/bin/ruby

require 'test/unit'
require 'ftools'

require 'hosttag'
include Hosttag

class TestHosttag < Test::Unit::TestCase
  def setup
    @test_args = '--server localhost --ns hosttag_testing'
    @test_opts = { :server => 'localhost', :namespace => 'hosttag_testing' }
    datadir = "#{File.dirname(__FILE__)}/data_hosttag"
    bindir = File.join(File.dirname(__FILE__), '..', 'bin')
    File.directory?(datadir) or throw "missing datadir #{datadir}"
    `#{bindir}/htimport #{@test_args} --delete --datadir #{datadir}`
  end

  # format: args (array), options (hash) => expected (array)
  SET1 = [
    [ %w{centos},           {},                 %w{a m n} ],
    [ %w{laptop},           {},                 %w{n} ],
    [ %w{vps},              {},                 %w{m} ],
    [ %w{laptop vps},       {},                 %w{} ],
    [ %w{laptop vps},       { :rel => :and },   %w{} ],
    [ %w{laptop vps},       { :rel => :or },    %w{m n} ],
    [ %w{n},                {},                 %w{centos centos5 centos5-i386 laptop} ],
    [ %w{a},                {},                 %w{centos centos5 centos5-x86_64 public} ],
    [ %w{m},                {},                 %w{centos centos4 centos4-x86_64 public vps} ],
    [ %w{a n},              {},                 %w{centos centos5 centos5-i386 centos5-x86_64 laptop public} ],
#   [ %w{-to a n},                %w{centos centos5 centos5-i386 centos5-x86_64 laptop public} ],
#   [ %w{-t -o a n},              %w{centos centos5 centos5-i386 centos5-x86_64 laptop public} ],
#   [ %w{-ta a n},                %w{centos centos5} ],
#   [ %w{-t -a a n},              %w{centos centos5} ],
#   [ %w{-t -a a n m},            %w{centos} ],
    # All cases
#   [ '-A',                     'a m n' ],
#   [ '-A -A',                  'a g h m n' ],
#   [ '-T',                     'centos centos4 centos4-x86_64 centos5 centos5-i386 centos5-x86_64 laptop public vps' ],
    # Try unrecognised tags as hosts
#   [ 'n',                      'centos centos5 centos5-i386 laptop' ],
#   [ 'a n',                    'centos centos5 centos5-i386 centos5-x86_64 laptop public' ],
    # Invalid data
#   [ 'foo',                    %r{ \btag\b  .* not\sfound }x ],
#   [ 'centos foo',             %r{ \btag\b  .* not\sfound }x ],
#   [ '-t foo',                 %r{ \bhost\b .* not\sfound }x ],
#   [ '-t n foo',               %r{ \bhost\b .* not\sfound }x ],
  ]

  def test_hosttag_lookup
    SET1.each do |args, opts, expected|
      opts.merge!(@test_opts)
      got = hosttag_lookup(args, opts)
      assert_equal(expected, got, "args: #{args}")
    end
  end

end

