output "analyticshub_subscription_viewer_custom_role_id" {
  description = "ID of the custom Analytics Hub Subscription Viewer role"
  value = local.has_folders ? (
    length(google_organization_iam_custom_role.analyticshub_custom_role_folder) > 0 ?
    google_organization_iam_custom_role.analyticshub_custom_role_folder[0].id : null
    ) : (
    length(google_project_iam_custom_role.analyticshub_custom_role_project) > 0 ?
    values(google_project_iam_custom_role.analyticshub_custom_role_project)[0].id : null
  )
}
