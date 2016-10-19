$parms = @{
    InitialNodeGrowth=10;
    ExcludedGroups=@("SOPHIS","InternalCloudNodes");
    NodeGroup = @("AzureNodes");
    NodeGrowth=3;
    TemplateSwitchNodeGrowth=4;
    CallQueueThreshold=2000;
    Sleep=30;
    NumOfQueuedJobsToGrowThreshold=2;
    GridMinsRemainingThreshold= 30
    TemplateUtilisationThreshold = 80;
    ShrinkThreshold = 5;
    AcceptableJTUtilisation = 50;
    AcceptableNodeUtilisation = 30;
    UnacceptableNodeUtilisation = 20
    }