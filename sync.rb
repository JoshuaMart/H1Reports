# frozen_string_literal: true

require 'json'
require 'typhoeus'

REPORTS_TO_SKIP = %w[not-applicable spam duplicate informative].freeze

def get_report_data(report_id)
  file_path = File.join('reports', "#{report_id}.json")
  return JSON.load_file(file_path) if File.exist?(file_path)

  resp = Typhoeus.get("https://hackerone.com/reports/#{report_id}.json")
  return unless resp&.code == 200

  data = JSON.parse(resp.body)
  return if data['visibility'] == 'no-content' ||
            REPORTS_TO_SKIP.include?(data['substate']) ||
            data.dig('team', 'profile', 'name').nil? ||
            data.to_s.include?('duplicate_report_id')

  File.open(file_path, 'w') { |f| f.write(JSON.pretty_generate(data)) }
end

def hackitivity_data(cursor)
  body = JSON.load_file('query.json')
  body['variables']['cursor'] = cursor

  resp = Typhoeus.post(
    'https://hackerone.com/graphql',
    headers: { 'Content-Type' => 'application/json' },
    body: body.to_json
  )
  return {} unless resp&.code == 200

  data = JSON.parse(resp.body)

  {
    'cursor' => data.dig('data', 'hacktivity_items', 'pageInfo', 'endCursor'),
    'has_next_page' => data.dig('data', 'hacktivity_items', 'pageInfo', 'hasNextPage'),
    'edges' => data.dig('data', 'hacktivity_items', 'edges')
  }
end

def sync_reports(cursor = '')
  data = hackitivity_data(cursor)

  data['edges']&.each do |edge|
    report_id = edge.dig('node', 'databaseId')
    report_file = File.join('reports', "#{report_id}.json")
    next if File.exist?(report_file)

    get_report_data(report_id)
  end

  sync_reports(data['cursor']) if data['has_next_page']
end

sync_reports
