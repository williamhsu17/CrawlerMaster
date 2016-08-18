##
# 竹教大課程查詢
# http://140.126.22.95/wbcmsc/cmain1.asp
#

module CourseCrawler::Crawlers
class NhcueCourseCrawler < CourseCrawler::Base

    DAYS = {
      "一" => 1,
      "二" => 2,
      "三" => 3,
      "四" => 4,
      "五" => 5,
      "六" => 6,
      "日" => 7,
    }

  def initialize  year: nil, term: nil , update_progress: nil, after_each: nil
    @year                 = year || current_year
    @term                 = term || current_term
    @after_each_proc      = after_each
    @update_progress_proc = update_progress

    @query_url = "http://140.126.22.95/wbcmsc/cmain1.asp"
    @ic = Iconv.new('utf-8//translit//IGNORE', 'big-5')
    @post_url = "http://140.126.22.95/wbcmsc/cdptgd1.asp"
  end

  def courses
    @courses = []
    puts "get url ..."
    # start write your crawler here:
    r = RestClient.get @query_url
    @cookies = r.cookies
    doc = Nokogiri::HTML(@ic.iconv(r))

    # r = RestClient.post(@post_url , {
    #   "submit2"=> "0",
    #   "qdptcd"=> "",
    #   "qdivis"=> "0",
    #   "qgd"=> "",
    #   "qschyy" => "#{year-1911}",
    #   "qsmt" => "#{term}",
    #   "action" => "%BDT%A9w",
    #   },{
    #
    #     })
    r = %x(curl -s 'http://140.126.22.95/wbcmsc/cdptgd1.asp' -H 'Cookie: ASPSESSIONIDSSDBBSQS=JLDLGBCCNFKGOJECMEAJMIOJ' -H 'Origin: http://140.126.22.95' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: zh-TW,zh;q=0.8,en-US;q=0.6,en;q=0.4' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Cache-Control: max-age=0' -H 'Referer: http://140.126.22.95/wbcmsc/cdptgd1.asp' -H 'Connection: keep-alive' --data 'submit2=0&qdptcd=&qdivis=0&qgd=&qschyy=#{year-1911}&qsmt=#{term}&action=%BDT%A9w' --compressed)

      # department = dept_names[index]
    doc = Nokogiri::HTML(@ic.iconv(r))
    doc.css('table')[1].text.strip

    # doc.css('table tr:not(:first-child)')[1].text.strip
    doc.css('table tbody tr').each do |row|
      puts "data crawled : " + row.css('td')[2].text.strip
      temp_data = row.css('td')[8].text.strip
      reg = /(?<day>[一二三四五六日])(?<start_time>[0-9]{2})-(?<stop_time>[0-9]{2})\((?<loc>[NA]{0,4}[0-9]{0,4}[AB]{0,4})\)/
      course_days = []
      course_periods = []
      course_locations = []

      arr = temp_data.split(',')

      arr.each do |str|
        str.match(reg) do |m|

            day = DAYS[m[:day]]

            start_period = m[:start_time].to_i
            end_period = m[:stop_time].to_i
            end_period = start_period if end_period == 0

            location = m[:loc]

            (start_period..end_period).each do |period|
              course_days << day
              course_periods << period
              course_locations << location
            end #period end
        end
      end

      course = {
        department:   row.css('td')[5].text.strip,
        name:         row.css('td')[2].text.strip,
        year:         @year,
        term:         @term,
        code:         "#{@year}-#{@term}-#{row.css('td')[1].text.strip}",
        general_code: row.css('td')[1].text.strip,
        # #{這個裡面放變數}
        credits:      row.css('td')[3].text.strip.to_i,
        required:     row.css('td')[6].text.include?('必'),
        lecturer:     row.css('td')[4].text.delete("\u00A0").strip,
        day_1:        course_days[0],
        day_2:        course_days[1],
        day_3:        course_days[2],
        day_4:        course_days[3],
        day_5:        course_days[4],
        day_6:        course_days[5],
        day_7:        course_days[6],
        day_8:        course_days[7],
        day_9:        course_days[8],
        period_1:     course_periods[0],
        period_2:     course_periods[1],
        period_3:     course_periods[2],
        period_4:     course_periods[3],
        period_5:     course_periods[4],
        period_6:     course_periods[5],
        period_7:     course_periods[6],
        period_8:     course_periods[7],
        period_9:     course_periods[8],
        location_1:   course_locations[0],
        location_2:   course_locations[1],
        location_3:   course_locations[2],
        location_4:   course_locations[3],
        location_5:   course_locations[4],
        location_6:   course_locations[5],
        location_7:   course_locations[6],
        location_8:   course_locations[7],
        location_9:   course_locations[8],
      }

      @after_each_proc.call(course: course) if @after_each_proc
      @courses << course
    end
    puts "Project finished !!!"
    @courses
  end # end courses method
end # end
end
