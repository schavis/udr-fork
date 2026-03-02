#!/usr/bin/env ruby
# Copyright IBM Corp. 2024, 2026
# SPDX-License-Identifier: BUSL-1.1


require 'octokit'

#
# Setup GitHub API client with access token
#

$github_token = ENV["GITHUB_TOKEN"]
raise "Missing GitHub token. Please set TOKEN in your environment." unless $github_token
$github = Octokit::Client.new(access_token: $github_token)

class PullRequest
  def initialize(repo, from, to)
    @dir = repo
    @repo = "hashicorp/#{repo}"
    @from = from
    @to = to
    @default_branch = $github.repository(@repo).default_branch
  end

  def generate
    # Use the local git history to find all merged PR numbers
    # --cherry-pick includes --merge (discovered experimentally)
    #
    # TODO: This checkout nonsense is quite silly, but it fixes
    #       "ambiguous argument" errors there must be a way to tell git not to
    #       require this.
    gitlog = `
      cd ../#{@dir} && \
      git fetch --tags --quiet && \
      git checkout --quiet #{@from} && \
      git checkout --quiet #{@default_branch} && \
      git checkout --quiet #{@to} && \
      git checkout --quiet #{@default_branch} && \
      git log --cherry-pick #{@from}..#{@to}
    `
    pr_numbers = parse_out_pr_numbers(gitlog)

    STDERR.puts "#{@repo}: #{pr_numbers.size} PRs"
    # Ask the GitHub API for information on each merged PR
    get_prs_from_github(pr_numbers)
  end

  def parse_out_pr_numbers(gitlog)
    pr_numbers = []

    gitlog.split("\n").each do |line|
      # Look for PRs that were regular merged
      line.match(/Merge pull request #(\d+)/) do |match|
        pr_numbers << match[1]
      end

      # Look for PRs that were squashed and merged
      line.match(/\(#(\d+)\)$/) do |match|
        pr_numbers << match[1]
      end
    end

    pr_numbers
  end

  def get_prs_from_github(pr_numbers)
    pr_numbers.reverse.map do |pr_number|
      # puts "retrieving pr #{pr_number}"
      pr = $github.pull_request(@repo.to_s, pr_number.to_i)
      
      # Check if this is a backport PR and find the original
      original_pr = find_original_pr(pr)
      
      if original_pr
        STDERR.puts "#{@repo}: Using original PR ##{original_pr.number} (by @#{original_pr.user.login}) instead of backport PR ##{pr.number}"
        original_pr
      else
        pr
      end
    end
  end

  def find_original_pr(pr)
    return nil unless pr.body

    # Look for auto-generated backport pattern (most common):
    # "This PR is auto-generated from #471"
    auto_generated_match = pr.body.match(/This PR is auto-generated from #(\d+)/i)
    
    if auto_generated_match
      original_pr_number = auto_generated_match[1].to_i
      STDERR.puts "#{@repo}: PR ##{pr.number} is auto-generated from ##{original_pr_number}"
      
      begin
        original_pr = $github.pull_request(@repo.to_s, original_pr_number)
        return original_pr
      rescue Octokit::NotFound
        STDERR.puts "#{@repo}: Warning - Original PR ##{original_pr_number} not found"
        return nil
      end
    end

    # Look for other common backport patterns in PR body:
    # - "Backport of #1234"
    # - "Backport: #1234"
    # - "Cherry-pick of #1234"
    # - "Backports #1234"
    backport_match = pr.body.match(/(?:backport|cherry-pick)(?:\s+of)?(?:\s*:)?\s*#(\d+)/i)
    
    if backport_match
      original_pr_number = backport_match[1].to_i
      STDERR.puts "#{@repo}: PR ##{pr.number} is a backport of ##{original_pr_number}"
      
      begin
        original_pr = $github.pull_request(@repo.to_s, original_pr_number)
        return original_pr
      rescue Octokit::NotFound
        STDERR.puts "#{@repo}: Warning - Original PR ##{original_pr_number} not found"
        return nil
      end
    end

    # Also check PR title for backport patterns
    title_match = pr.title.match(/(?:backport|cherry-pick)(?:\s+of)?(?:\s*:)?\s*#(\d+)/i)
    
    if title_match
      original_pr_number = title_match[1].to_i
      STDERR.puts "#{@repo}: PR ##{pr.number} (from title) is a backport of ##{original_pr_number}"
      
      begin
        original_pr = $github.pull_request(@repo.to_s, original_pr_number)
        return original_pr
      rescue Octokit::NotFound
        STDERR.puts "#{@repo}: Warning - Original PR ##{original_pr_number} not found"
        return nil
      end
    end

    nil
  end
end
