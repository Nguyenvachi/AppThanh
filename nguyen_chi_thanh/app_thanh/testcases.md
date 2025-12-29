# Test Cases cho Ứng Dụng

Dưới đây là danh sách các test case dựa trên yêu cầu chức năng:

## 1. Chức năng Đăng xuất
**TC01: Đăng xuất từ màn hình Admin**
- **Mô tả:** Kiểm tra chức năng đăng xuất khỏi tài khoản Admin.
- **Tiền điều kiện:** Đã đăng nhập bằng tài khoản Admin.
- **Các bước:**
  1. Tại màn hình Admin Dashboard, nhấn vào biểu tượng Logout (góc trên bên phải).
- **Kết quả mong đợi:** Token và Role bị xóa khỏi bộ nhớ, ứng dụng chuyển về màn hình Đăng nhập (LoginScreen).

**TC02: Đăng xuất từ màn hình User**
- **Mô tả:** Kiểm tra chức năng đăng xuất khỏi tài khoản User.
- **Tiền điều kiện:** Đã đăng nhập bằng tài khoản User.
- **Các bước:**
  1. Vào tab "Cá nhân" (InformationScreen).
  2. Nhấn nút "Đăng xuất".
- **Kết quả mong đợi:** Token và Role bị xóa khỏi bộ nhớ, ứng dụng chuyển về màn hình Đăng nhập.

## 2 & 3. Đăng nhập và Phân quyền (Login Logic)
**TC03: Đăng nhập tài khoản Admin**
- **Mô tả:** Kiểm tra đăng nhập với tài khoản có quyền Admin.
- **Tiền điều kiện:** Có tài khoản Admin hợp lệ.
- **Các bước:**
  1. Tại màn hình Login, nhập Username/Password của Admin.
  2. Nhấn Đăng nhập.
- **Kết quả mong đợi:** Chuyển hướng thành công vào màn hình Admin Dashboard (AdminScreen). Không vào giao diện User.

**TC04: Đăng nhập tài khoản User**
- **Mô tả:** Kiểm tra đăng nhập với tài khoản User thường.
- **Tiền điều kiện:** Có tài khoản User hợp lệ.
- **Các bước:**
  1. Tại màn hình Login, nhập Username/Password của User.
  2. Nhấn Đăng nhập.
- **Kết quả mong đợi:** Chuyển hướng thành công vào màn hình chính của User (HomeScreen).

**TC05: Duy trì phiên đăng nhập Admin (Khởi động lại app)**
- **Mô tả:** Kiểm tra app ghi nhớ quyền Admin sau khi thoát.
- **Tiền điều kiện:** Đã đăng nhập Admin thành công.
- **Các bước:**
  1. Thoát hẳn ứng dụng (Kill app).
  2. Mở lại ứng dụng.
- **Kết quả mong đợi:** App tự động kiểm tra token và chuyển thẳng vào Admin Dashboard, không bị vào nhầm HomeScreen.

## 4. Phân quyền lấy danh sách sản phẩm
**TC06: Lấy danh sách sản phẩm khi đã đăng nhập**
- **Mô tả:** Kiểm tra quyền xem sản phẩm.
- **Tiền điều kiện:** Đã đăng nhập (User hoặc Admin).
- **Các bước:**
  1. Vào màn hình Market.
- **Kết quả mong đợi:** Danh sách sản phẩm được tải và hiển thị thành công.

**TC07: Lấy danh sách sản phẩm khi chưa đăng nhập (Giả lập)**
- **Mô tả:** Đảm bảo API yêu cầu token.
- **Tiền điều kiện:** Xóa token hoặc token hết hạn.
- **Các bước:**
  1. Cố gắng gọi API fetchProducts.
- **Kết quả mong đợi:** Ứng dụng báo lỗi "Authentication required" hoặc chuyển về màn hình Login.

## 5. Smart Auth
**TC08: Gợi ý đăng nhập Smart Auth (Android)**
- **Mô tả:** Kiểm tra tính năng gợi ý số điện thoại/email.
- **Tiền điều kiện:** Chạy trên thiết bị Android, có lưu tài khoản Google/SĐT.
- **Các bước:**
  1. Tại màn hình Login, nhấn nút "Gợi ý SĐT/Email (SmartAuth)".
- **Kết quả mong đợi:** Hiện dialog chọn tài khoản/SĐT. Khi chọn, thông tin tự động điền vào ô Username (và Password nếu có).

## 6, 7 & 8. Quản lý Danh mục và Sản phẩm
**TC09: Thêm danh mục sản phẩm (Admin)**
- **Mô tả:** Admin thêm danh mục mới.
- **Tiền điều kiện:** Đăng nhập Admin.
- **Các bước:**
  1. Vào "Quản lý Danh Mục Sản Phẩm".
  2. Nhấn nút thêm (+).
  3. Nhập tên và mô tả, nhấn Lưu.
- **Kết quả mong đợi:** Danh mục mới xuất hiện trong danh sách.

**TC10: Gán danh mục cho sản phẩm**
- **Mô tả:** Đảm bảo sản phẩm có thể chọn danh mục.
- **Tiền điều kiện:** Đăng nhập Admin, đã có ít nhất 1 danh mục.
- **Các bước:**
  1. Vào "Quản lý Sản Phẩm" -> Thêm/Sửa sản phẩm.
  2. Tại dropdown "Danh mục sản phẩm", chọn một danh mục.
  3. Lưu sản phẩm.
- **Kết quả mong đợi:** Sản phẩm được lưu với categoryId tương ứng.

**TC11: Xóa danh mục và ảnh hưởng tới sản phẩm**
- **Mô tả:** Khi xóa danh mục, các sản phẩm thuộc danh mục đó sẽ không còn thuộc danh mục nào (categoryId = null).
- **Tiền điều kiện:** Có 1 danh mục "A" và 1 sản phẩm "P" thuộc danh mục "A".
- **Các bước:**
  1. Vào "Quản lý Danh Mục Sản Phẩm".
  2. Xóa danh mục "A".
  3. Xác nhận xóa.
- **Kết quả mong đợi:** Danh mục "A" bị xóa. Sản phẩm "P" vẫn tồn tại nhưng thông tin danh mục trở về trống (null).
