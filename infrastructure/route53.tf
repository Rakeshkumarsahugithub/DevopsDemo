# Route 53 Hosted Zone (uncomment if you want to manage DNS with Terraform)
# resource "aws_route53_zone" "main" {
#   name = var.domain_name
#
#   tags = {
#     Name        = "${var.project_name}-zone"
#     Environment = var.environment
#   }
# }

# ACM Certificate for HTTPS
# resource "aws_acm_certificate" "cert" {
#   domain_name       = var.domain_name
#   validation_method = "DNS"
#   subject_alternative_names = ["*.${var.domain_name}"]
#
#   lifecycle {
#     create_before_destroy = true
#   }
#
#   tags = {
#     Name        = "${var.project_name}-cert"
#     Environment = var.environment
#   }
# }

# DNS validation records
# resource "aws_route53_record" "cert_validation" {
#   for_each = {
#     for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   }
#
#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = aws_route53_zone.main.zone_id
# }

# Certificate validation
# resource "aws_acm_certificate_validation" "cert" {
#   certificate_arn         = aws_acm_certificate.cert.arn
#   validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
# }

# Route 53 record for ALB
# resource "aws_route53_record" "api" {
#   zone_id = aws_route53_zone.main.zone_id
#   name    = "api.${var.domain_name}"
#   type    = "A"
#
#   alias {
#     name                   = aws_lb.main.dns_name
#     zone_id                = aws_lb.main.zone_id
#     evaluate_target_health = true
#   }
# }

# Route 53 record for CloudFront
# resource "aws_route53_record" "www" {
#   zone_id = aws_route53_zone.main.zone_id
#   name    = var.domain_name
#   type    = "A"
#
#   alias {
#     name                   = aws_cloudfront_distribution.frontend.domain_name
#     zone_id                = aws_cloudfront_distribution.frontend.hosted_zone_id
#     evaluate_target_health = false
#   }
# }
