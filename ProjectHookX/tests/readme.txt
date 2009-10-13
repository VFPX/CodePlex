This test project uses two very simple test project hooks. All methods of both hooks prompt the user with the name of the hook so that it is obvious which hook is running. The PositiveHook returns .T. from all methods and the NegativeHook returns .F. from all methods.

The default value for the lAlwaysProceed property of ProjectHookX is is .T. which means the the action taken on the project will always happen even though the NegativeHook returns .F.

To prohibit the default behavior and force the return value from the NegativeHook to stop execution, set the lAlwaysProceed property to .F. using the following code:

_vfp.ActiveProject.ProjectHook.lAlwaysProceed = .F.