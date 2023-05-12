domain    = "core"
env       = "prod"
env_short = "p"
prefix    = "news"

environment_cd_roles = {
  subscription = [
    # "Reader",
  ]
  resource_groups = {
    news-p-weu-core-app-rg = [
      "Website Contributor",
    ]
  }
}

github_repository_environment_cd = {
  reviewers_teams = []
}
