import * as OneSignal from '@onesignal/node-onesignal';
import { getConfig } from '../../../../shared/index.js';

let oneSignalClient = null;
let oneSignalAppId = null;

export const initializeOneSignal = () => {
  const appAuthKey = getConfig('ONESIGNAL_REST_API_KEY');
  oneSignalAppId = getConfig('ONESIGNAL_APP_ID');

  if (!appAuthKey || !oneSignalAppId) {
    console.warn('⚠️ OneSignal credentials missing. Push notifications will happen in dry-run mode (if handled) or fail.');
    console.warn('  ONESIGNAL_REST_API_KEY:', appAuthKey ? 'set' : 'missing');
    console.warn('  ONESIGNAL_APP_ID:', oneSignalAppId ? 'set' : 'missing');
    return null;
  }

  // Create configuration with the new SDK
  const configuration = OneSignal.createConfiguration({
    restApiKey: appAuthKey,
  });

  oneSignalClient = new OneSignal.DefaultApi(configuration);

  console.log('✅ OneSignal client initialized with App ID:', oneSignalAppId);
  return oneSignalClient;
};

export const getOneSignalClient = () => {
  if (!oneSignalClient) {
    // Attempt lazy init if not explicitly initialized (though bootstrap should handle it)
    return initializeOneSignal();
  }
  return oneSignalClient;
};

export const getOneSignalAppId = () => oneSignalAppId;

export default getOneSignalClient;
