# 1. Xóa dữ liệu cũ
puts "--- Đang dọn dẹp dữ liệu cũ ---"
ReviewAuditLog.delete_all
Story.delete_all
Kanji.delete_all
User.delete_all

# 2. Tạo tài khoản
puts "--- Đang tạo 10 Admin và 10 User ---"
10.times { |i| User.create!(email: "admin#{i+1}@kanji.com", role: 1) }
users = []
10.times { |i| users << User.create!(email: "contributor#{i+1}@spring.com", role: 0) }

# 3. Tạo Kanji gốc ĐẦY ĐỦ THÔNG TIN
puts "--- Đang tạo Kanji gốc đầy đủ chi tiết ---"
kanji_data = [
  {
    character: "木",
    translation: "MỘC",
    meaning: "Cây, gỗ",
    onyomi: "ボク、モク",
    kunyomi: "き、こ",
    jlpt_level: 5,
    stroke_count: 4,
    radical: "木",
    components: "木",
    kanji_story: "Hình ảnh một cái cây có tán lá phía trên và rễ đâm xuống đất.",
    examples: "木材 (Mộc tài): Gỗ\n木曜日 (Mộc diệu nhật): Thứ năm",
    example_sentences: "木の下で休む。 (Nghỉ ngơi dưới gốc cây.)",
    writing_image_url: "https://mazii.net/assets/kanji/06728.svg"
  },
  {
    character: "日",
    translation: "NHẬT",
    meaning: "Ngày, mặt trời",
    onyomi: "ニチ、ジツ",
    kunyomi: "ひ、か",
    jlpt_level: 5,
    stroke_count: 4,
    radical: "日",
    components: "日",
    kanji_story: "Hình ảnh mặt trời hình tròn với một vạch ngang ở giữa.",
    examples: "日本 (Nhật bản): Nước Nhật\n毎日 (Mỗi nhật): Hàng ngày",
    example_sentences: "今日はいい天気です。 (Hôm nay thời tiết đẹp.)",
    writing_image_url: "https://mazii.net/assets/kanji/065e5.svg"
  },
  {
    character: "水",
    translation: "THỦY",
    meaning: "Nước",
    onyomi: "スイ",
    kunyomi: "みず",
    jlpt_level: 5,
    stroke_count: 4,
    radical: "水",
    components: "水",
    kanji_story: "Hình ảnh dòng nước chảy xiết với các tia nước bắn ra.",
    examples: "水泳 (Thủy vịnh): Bơi lội\n水道 (Thủy đạo): Nước máy",
    example_sentences: "水を飲みます。 (Tôi uống nước.)",
    writing_image_url: "https://mazii.net/assets/kanji/06c34.svg"
  },
  {
    character: "火",
    translation: "HỎA",
    meaning: "Lửa",
    onyomi: "カ",
    kunyomi: "ひ、ほ",
    jlpt_level: 5,
    stroke_count: 4,
    radical: "火",
    components: "火",
    kanji_story: "Hình ảnh một đống lửa đang bùng cháy với hai tia lửa bắn ra hai bên.",
    examples: "火曜日 (Hỏa diệu nhật): Thứ ba\n火山 (Hỏa sơn): Núi lửa",
    example_sentences: "火に気をつけてください。 (Hãy cẩn thận với lửa.)",
    writing_image_url: "https://mazii.net/assets/kanji/0706b.svg"
  }
]

kanji_data.each { |data| Kanji.create!(data) }

# 4. Tạo bài đóng góp chờ duyệt (Stories) để test
puts "--- Đang tạo các bài đóng góp chờ duyệt ---"
# Tạo 5 đóng góp cho chữ "木" để test tính năng quản lý đóng góp
5.times do |i|
  Story.create!(
    title: "木",
    definition: "Câu chuyện thứ #{i+1} của User về chữ Mộc để Admin chọn lọc.",
    user: users.sample,
    status: :pending
  )
end

# Tạo các chữ mới hoàn toàn chưa có trong hệ thống
["月", "金", "土", "人", "山"].each do |char|
  Story.create!(
    title: char,
    definition: "Người dùng đóng góp cách nhớ cho chữ #{char}.",
    user: users.sample,
    status: :pending
  )
end

puts "--- SEED THÀNH CÔNG! ---"