trigger AccountTrigger on Account (before insert , after insert) {
    if(Trigger.isBefore) {
        if(Trigger.isInsert) {
            for(Account acc: Trigger.new) {
                if(acc.Type == null) {
                    acc.Type = 'Prospect';
                }
            }
        }
    }

    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            Set<Id> accountIds = new Set<Id>();
            List<Account> accountsToUpdateForBillingAdd = new List<Account>();
            List<Account> accountsToUpdateForRating = new List<Account>();
            for(Account acc: Trigger.new) {
                accountIds.add(acc.Id);
                if(acc.ShippingStreet != null && acc.ShippingCity != null && acc.ShippingState != null && acc.ShippingCountry != null && acc.ShippingPostalCode != null) {
                    Account proxyAcc = new Account(Id = acc.Id,
                    BillingStreet = acc.ShippingStreet,
                    BillingCity = acc.ShippingCity,
                    BillingState = acc.ShippingState,
                    BillingCountry = acc.ShippingCountry,
                    BillingPostalCode = acc.ShippingPostalCode);
                    accountsToUpdateForBillingAdd.add(proxyAcc);
                }
                if(acc.Phone != null && acc.Website != null && acc.Fax != null){
                    Account proxyAcc = new Account(Id = acc.Id, Rating = 'Hot');
                    accountsToUpdateForRating.add(proxyAcc);
                }
            }
            update accountsToUpdateForBillingAdd;
            update accountsToUpdateForRating;
            
            List<Account> accountsWithDefaultContact = new List<Account>([SELECT Id, (SELECT Id FROM Contacts WHERE LastName = 'DefaultContact' AND Email = 'default@email.com') FROM Account WHERE Id IN :accountIds]);
            List<Contact> contactToCreate = new List<Contact>();
            for(Account acc: accountsWithDefaultContact) {
                if(acc.Contacts.isEmpty()) {
                    contactToCreate.add(new Contact(AccountId = acc.Id, LastName = 'DefaultContact', Email = 'default@email.com'));
                }
            }
            insert contactToCreate;
        }
    }
}