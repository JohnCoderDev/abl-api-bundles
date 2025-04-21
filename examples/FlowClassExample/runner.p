using classes.APIBundles.* from propath.

define variable runner as APIFlowRunner no-undo.

assign runner = new APIFlowRunner().

runner:addFlow('example', 'FlowClassExample.FlowExample').

runner:runFlows().
