# Application Platform Services

Repository này chứa **Application Layer** (Lớp ứng dụng). Nó chịu trách nhiệm triển khai các dịch vụ chạy trên nền tảng AWS như ECS, RDS, ALB, và ElastiCache.

## 🏗️ Kiến trúc & Liên kết

Đây là repo sử dụng các tài nguyên từ `base-infras` để chạy ứng dụng.

### Cách liên kết (Linking)

1. **Source Layer (`terraform-module`)**: 
   - Repo này gọi code từ `terraform-module` cho các tài nguyên app.
   - Ví dụ: `source = "git::https://github.com/.../terraform-module.git//modules/ecs-service?ref=master"`

2. **Infrastructure Layer (`base-infras`)**:
   - `aws-services-app` **đọc dữ liệu** từ Remote State của `base-infras`.
   - Sử dụng `data "terraform_remote_state" "vpc"` để lấy `vpc_id`, `private_subnets`, v.v. Điều này giúp lớp ứng dụng luôn khớp với lớp hạ tầng nền.

## 📂 Các tài nguyên quản lý

- **Compute**: ECS Cluster, ECS Services (Fargate).
- **Traffic**: Application Load Balancer (ALB), Target Groups.
- **Database**: Amazon RDS (PostgreSQL/MySQL), ElastiCache (Redis).

## 🚀 Cách triển khai

1. Chỉnh sửa cấu hình dịch vụ trong thư mục `deployments/dev/services/` (ví dụ: `api.yml`, `database.yml`).
2. Pipeline sẽ tự động nhận diện dịch vụ nào thay đổi và chạy `terraform plan`.
3. Kiểm tra kết quả plan và thực hiện `apply`.

> [!TIP]
> Bạn có thể tạo thêm các file `.yml` mới trong thư mục `services/` để triển khai thêm các microservices mới một cách nhanh chóng.
