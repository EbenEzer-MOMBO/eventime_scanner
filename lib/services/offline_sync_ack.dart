/// Codes batch à retirer de la file locale.
const ackBatchResults = {'ok', 'already_scanned'};

bool shouldAckBatchResult(String result) => ackBatchResults.contains(result);
