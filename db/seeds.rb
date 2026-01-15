# db/seeds.rb

# 1. Xóa dữ liệu cũ để tránh trùng lặp khi chạy lại lệnh seed
ReviewAuditLog.delete_all
Story.delete_all
User.delete_all

# 2. Tạo một tài khoản Admin mẫu để thực hiện duyệt bài
# (Giả sử hệ thống của bạn dùng email để định danh)
admin = User.create!(
  email: "admin@kanji.com",
  role: 1 # 1 tương ứng với :admin trong enum của bạn
)

# 3. Tạo một tài khoản User mẫu (người đóng góp bài viết)
contributor = User.create!(
  email: "user_test@spring.com",
  role: 0 # 0 tương ứng với :user
)

# 4. Tạo các bài Kanji mẫu với trạng thái Đang chờ duyệt (Pending)
stories = [
  {
    title: "東",
    definition: "Hình t là con ngươi.",
    example: "目が痛い (Tôi bị đau mắt)",
    user: contributor,
    status: :pending
  },
  {
    title: "漢",
    definition: "Hình tượngsdasd Hai gạch bên trong là con ngươi.",
    example: "目が痛い (Tôi bị đau mắt)",
    user: contributor,
    status: :pending
  },
  {
    title: "口",
    definition: "Vẽ lại hình dáng của cái miệng đang mở.",
    example: "口を開ける (Mở miệng ra)",
    user: contributor,
    status: :pending
  },
  {
    title: "昨",
    definition: "sdsdsdsddbang mở.",
    example: "dddddđ )",
    user: contributor,
    status: :pending
  },
  {
    title: "先",
    definition: "mo.",
    example: "dddddđ )",
    user: contributor,
    status: :pending
  },
  {
    title: "木",
    definition: "Hình ảnh một cái cây có tán lá và rễ đâm xuống đất.",
    example: "木の下で休む (Nghỉ ngơi dưới gốc cây)",
    user: contributor,
    status: :pending
  }

]

stories.each do |s|
  Story.create!(s)
end

puts "--- Đã tạo thành công 1 Admin, 1 User và bài Kanji chờ duyệt! ---"