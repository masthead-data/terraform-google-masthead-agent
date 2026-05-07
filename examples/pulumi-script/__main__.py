import pulumi_masthead_agent as masthead_agent

masthead_agent.Module(
    "masthead-agent",
    project_id='PROJECT_ID',  # Replace with your actual project ID
    enable_modules={
        "bigquery": True,
        "dataform": False,
        "dataplex": False,
        "analytics_hub": False,
    }
)
