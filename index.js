const AWS = require('aws-sdk');
const ec2 = new AWS.EC2();

exports.handler = async (event) => {
    const instanceId = process.env.INSTANCE_ID;
    
    // Get the current state of the instance
    try {
        const params = {
            InstanceIds: [instanceId],
        };

        const response = await ec2.describeInstances(params).promise();
        const state = response.Reservations[0].Instances[0].State.Name;
        console.log(`Instance ${instanceId} is currently in ${state} state.`);

        // Check if the instance is in the stopped state
        if (state === 'stopped') {
            console.log(`Terminating instance ${instanceId} as it is in a stopped state.`);
            await ec2.terminateInstances({ InstanceIds: [instanceId] }).promise();
            return {
                statusCode: 200,
                body: JSON.stringify(`Instance ${instanceId} terminated successfully.`),
            };
        } else {
            return {
                statusCode: 200,
                body: JSON.stringify(`Instance ${instanceId} is in a running state, no action taken.`),
            };
        }
    } catch (error) {
        console.error('Error:', error);
        return {
            statusCode: 500,
            body: JSON.stringify('Error occurred while checking instance status.'),
        };
    }
};