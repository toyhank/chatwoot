#!/usr/bin/env ruby
# 测试脚本: 为正确的联系人注册推送订阅

require 'net/http'
require 'json'
require 'uri'

# 配置
BASE_URL = 'http://localhost:3000'
WEBSITE_TOKEN = 'GJFzMx6qnv9DFpaspRpFDRDt'  # 从数据库获取
FCM_TOKEN = 'fLFFC_OFSsmjgePnZCTScA:APA91bE8gXOZ4XxcouXAmsu_euPq5551uRNhXg17k43Plc6WQxYVL42MrpXtbXy9F5nXoE8H134JfmXEpS7uygpztESBNmhYPtOaDqs_xxU8p3NysHWxRZQ'
DEVICE_ID = Time.now.to_i.to_s  # 使用时间戳作为设备ID

puts "=" * 80
puts "推送订阅注册测试"
puts "=" * 80

# 步骤1: 设置用户身份
puts "\n步骤1: 设置用户身份为 yushuangqi@hotmail.com"
puts "-" * 80

set_user_url = URI("#{BASE_URL}/api/v1/widget/contact/set_user")
set_user_request = Net::HTTP::Post.new(set_user_url)
set_user_request['Content-Type'] = 'application/json'

set_user_body = {
  website_token: WEBSITE_TOKEN,
  identifier: 'yushuangqi@hotmail.com',
  name: 'toy'
}

puts "请求URL: #{set_user_url}"
puts "请求Body: #{JSON.pretty_generate(set_user_body)}"

http = Net::HTTP.new(set_user_url.host, set_user_url.port)
set_user_request.body = set_user_body.to_json

begin
  set_user_response = http.request(set_user_request)
  puts "\n响应状态: #{set_user_response.code}"
  puts "响应Body: #{JSON.pretty_generate(JSON.parse(set_user_response.body))}"
  
  response_data = JSON.parse(set_user_response.body)
  auth_token = response_data['pubsub_token']
  source_id = response_data['source_id']
  
  puts "\n✓ 获取到 Auth Token: #{auth_token}"
  puts "✓ Source ID: #{source_id}"
  
  # 步骤2: 注册推送订阅
  puts "\n" + "=" * 80
  puts "步骤2: 使用正确的 Auth Token 注册推送订阅"
  puts "-" * 80
  
  push_sub_url = URI("#{BASE_URL}/api/v1/widget/push_subscriptions")
  push_sub_request = Net::HTTP::Post.new(push_sub_url)
  push_sub_request['Content-Type'] = 'application/json'
  push_sub_request['X-Auth-Token'] = auth_token  # 使用正确的 auth token
  
  push_sub_body = {
    website_token: WEBSITE_TOKEN,
    push_subscription: {
      push_token: FCM_TOKEN,
      device_id: DEVICE_ID,
      platform: 'android'
    }
  }
  
  puts "请求URL: #{push_sub_url}"
  puts "请求Headers: X-Auth-Token = #{auth_token}"
  puts "请求Body: #{JSON.pretty_generate(push_sub_body)}"
  
  push_sub_request.body = push_sub_body.to_json
  push_sub_response = http.request(push_sub_request)
  
  puts "\n响应状态: #{push_sub_response.code}"
  puts "响应Body: #{JSON.pretty_generate(JSON.parse(push_sub_response.body))}"
  
  if push_sub_response.code == '201'
    puts "\n✓ 推送订阅注册成功!"
    subscription_data = JSON.parse(push_sub_response.body)
    puts "  - 订阅ID: #{subscription_data['id']}"
    puts "  - 联系人ID: #{subscription_data['contact_id']}"
    puts "  - Contact Inbox ID: #{subscription_data['contact_inbox_id']}"
  else
    puts "\n✗ 推送订阅注册失败"
  end
  
rescue StandardError => e
  puts "\n错误: #{e.message}"
  puts e.backtrace.join("\n")
end

puts "\n" + "=" * 80
puts "测试完成"
puts "=" * 80
