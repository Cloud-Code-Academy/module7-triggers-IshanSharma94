trigger OpportunityTrigger on Opportunity (before update, before delete) {
    if(Trigger.isBefore) {
        if(Trigger.isUpdate) {
            Set<Id> accountIds = new Set<Id>();
            for(Opportunity opp: Trigger.new) {
                accountIds.add(opp.AccountId);
                if(opp.Amount < 5000) {
                    opp.Amount.addError('Opportunity amount must be greater than 5000');
                }
            }
            Map<Id,Contact> accountsWithCEOContact = new Map<Id,Contact>();
            for(Account acc: [SELECT Id, (SELECT Id FROM Contacts WHERE Title = 'CEO' LIMIT 1) FROM Account WHERE Id IN :accountIds]) {
                if(!acc.Contacts.isEmpty()) {
                    accountsWithCEOContact.put(acc.Id, acc.Contacts[0]);
                }
            }
            for(Opportunity opp: Trigger.new) {
                if(accountsWithCEOContact.containsKey(opp.AccountId)) {
                    opp.Primary_Contact__c = accountsWithCEOContact.get(opp.AccountId).Id;
                }
            }
        }
        if(Trigger.isDelete) {
            Map<Id,Opportunity> oppsWithBankingAccount = new Map<Id,Opportunity>([SELECT Id, Account.Industry FROM Opportunity WHERE Account.Industry = 'Banking' and StageName = 'Closed Won' AND Id IN :Trigger.old]);
            for(Opportunity opp: Trigger.old) {
                if(oppsWithBankingAccount.containsKey(opp.Id)) {
                    opp.addError('Cannot delete closed opportunity for a banking account that is won');
                }
            }
        }
    }
}