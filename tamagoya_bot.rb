require 'nokogiri'
require 'kconv'
require 'date'
require 'net/http'
require 'uri'
require 'json'

MENU_URL = '玉子屋メニューのURL'
WEBHOOK_URL = 'TocaroのWebhook URL'

def get_nokogiri_html(url)
  charset = 'utf-8'
  html = `curl -s #{url}`.toutf8
  doc = Nokogiri::HTML.parse(html, nil, charset)
end

def tamagoya_parser(html)
  arr = []
  html.xpath("//div[@class='item']").each do |node|
    day = node.xpath('h3').text.match(/\d{1,2}.\(.\)/).to_s
    main_menu = node.xpath('h3').text.gsub(/ |\r|\n/, "").match(/\d{1,2}.\(.\)/).post_match.to_s
    sub_menu = node.xpath("p[@class='text']").text.gsub(/ |\r/, "")
    arr << [day, main_menu, sub_menu]
  end
  arr
end

def post_to_webhook(url, text, info, title, value)
  # Webhookの仕様はTocaroの公式ページで確認してください。
  uri  = URI.parse(url)
  params = { text: text, color: info, attachments: [title: title, value: value] }
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.start do
    request = Net::HTTP::Post.new(uri.path)
    request.set_form_data(payload: params.to_json)
    http.request(request)
  end
end

def tamagoya_bot
  today = Date.today
  num_of_today = today.wday.to_i - 1 # Dateクラスwdayメソッドの曜日番号が日曜始まり（0-6/日-土）であるため，-1で月曜始まりに調整。
  menu_html = get_nokogiri_html(MENU_URL)
  weekly_menu = tamagoya_parser(menu_html)
  message = today.month.to_s + "月" + today.day.to_s + "日(" + %w(日 月 火 水 木 金 土)[today.wday] + ")の玉子屋メニューです。"
  main_menu = weekly_menu[num_of_today][1]
  sub_menu = weekly_menu[num_of_today][2]
  if sub_menu == "" then
    message = "本日" + today.month.to_s + "月" + today.day.to_s + "日(" + %w(日 月 火 水 木 金 土)[today.wday] + ")，玉子屋はお休みです。"
  end
  post_to_webhook(WEBHOOK_URL, message, "info", main_menu, sub_menu)
end

tamagoya_bot
