$parms = @{
    InitialNodeGrowth=10;
    ExcludedGroups=@("SOPHIS","InternalCloudNodes");
    NodeGroup = @("AzureNodes");
    NodeGrowth=3;
    TemplateSwitchNodeGrowth=4;
    CallQueueThreshold=2000;
    Sleep=30;
    NumOfQueuedJobsToGrowThreshold=1;
    GridMinsRemainingThreshold= 20;
    TemplateUtilisationThreshold = 80;
    ShrinkThreshold = 6
    }