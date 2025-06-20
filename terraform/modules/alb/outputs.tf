output "alb_arn" {
  value = module.alb.this_lb_arn
}

output "alb_dns_name" {
  value = module.alb.this_lb_dns_name
} 