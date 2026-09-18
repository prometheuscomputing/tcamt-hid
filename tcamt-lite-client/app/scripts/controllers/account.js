'use strict';

/* "newcap": false */

angular.module('tcl')
.controller('UserProfileCtrl', ['$scope', '$rootScope', '$resource', 'AccountLoader', 'Account', 'userInfoService', '$location',
    function ($scope, $rootScope, $resource, AccountLoader, Account, userInfoService, $location) {
        var PasswordChange = $resource('api/accounts/:id/passwordchange', {id:'@id'});

        $scope.accountpwd = {};

        $scope.initModel = function(data) {
            $scope.account = data;
            $scope.accountOrig = angular.copy($scope.account);
        };

        $scope.updateAccount = function() {
            //not sure it is very clean...
            //TODO: Add call back?
            new Account($scope.account).$save();

            $scope.accountOrig = angular.copy($scope.account);
        };

        $scope.resetForm = function() {
            $scope.account = angular.copy($scope.accountOrig);
        };

        //TODO: Change that: formData is only supported on modern browsers
        $scope.isUnchanged = function(formData) {
            return angular.equals(formData, $scope.accountOrig);
        };


        $scope.changePassword = function() {
            var user = new PasswordChange();
            user.username = $scope.account.username;
            user.password = $scope.accountpwd.currentPassword;
            user.newPassword = $scope.accountpwd.newPassword;
            user.id = $scope.account.id;
            user.$save().then(function(result){
                var payload = angular.fromJson(result);
                if (payload.type === 'success') {
                    $scope.accountpwd = {};
                    var message = $.i18n.prop('accountPasswordReset');
                    $rootScope.notifyUser('success', message, 2000);
                }
            });
        };

        $scope.deleteAccount = function () {
            var tmpAcct = new Account();
            tmpAcct.id = $scope.account.id;

            tmpAcct.$remove(function() {
                //console.log("Account removed");
                //TODO: Add a real check?
                userInfoService.setCurrentUser(null);
                $rootScope.authenticated = false;

                $scope.$emit('event:logoutRequest');
                $location.url('/home');
            });
        };

        /*jshint newcap:false */
        AccountLoader(userInfoService.getAccountID()).then(
            function(data) {
                $scope.initModel(data);
                if (!$scope.$$phase) {
                    $scope.$apply();
                }
            },
            function() {
//                console.log('Error fetching account information');
            }
        );
    }
]);


angular.module('tcl')
    .controller('UserAccountCtrl', ['$scope', '$resource', 'AccountLoader', 'Account', 'userInfoService', '$location', '$rootScope',
        function ($scope, $resource, AccountLoader, Account, userInfoService, $location,$rootScope) {


            $scope.accordi = { account : true, accounts:false};
            $scope.setSubActive = function (id) {
                if(id && id != null) {
                    $rootScope.setSubActive(id);
                    $('.accountMgt').hide();
                    $('#' + id).show();
                }
            };
            $scope.initAccount = function(){
                if($rootScope.subActivePath == null){
                    $rootScope.subActivePath = "account";
                }
                $scope.setSubActive($rootScope.subActivePath);
            };


        }
    ]);

'use strict';

angular.module('tcl')
    .controller('AccountsListCtrl', ['$scope', 'MultiAuthorsLoader', 'MultiSupervisorsLoader','Account', '$modal', '$resource','AccountLoader','userInfoService','$location',
        function ($scope, MultiAuthorsLoader, MultiSupervisorsLoader, Account, $modal, $resource, AccountLoader, userInfoService, $location) {

            //$scope.accountTypes = [{ 'name':'Author', 'type':'author'}, {name:'Supervisor', type:'supervisor'}];
            //$scope.accountType = $scope.accountTypes[0];
            $scope.tmpAccountList = [].concat($scope.accountList);
            $scope.account = null;
            $scope.accountOrig = null;
            $scope.accountType = "author";
            $scope.scrollbarWidth = $scope.getScrollbarWidth();

            $scope.loadAccounts = function(){
                if (userInfoService.isAuthenticated() && userInfoService.isAdmin()) {
                    new MultiAuthorsLoader().then(function (response) {
                        $scope.accountList = response;
                        $scope.tmpAccountList = [].concat($scope.accountList);
                    });
                }
            };

            $scope.initManageAccounts = function(){
                $scope.loadAccounts();
            };

            var ApproveAccount = $resource('api/accounts/:id/approveaccount', {id:'@id'});
            var SuspendAccount = $resource('api/accounts/:id/suspendaccount', {id:'@id'});

            $scope.approveAccount = function(row) {
                var user = new ApproveAccount();
                user.username = row.username;
                user.id = row.id;
                user.$save().then(function() {
                    row.pending = false;
                });
            };

            $scope.suspendAccount = function(row) {
                var user = new SuspendAccount();
                user.username = row.username;
                user.id = row.id;
                user.$save().then(function() {
                    row.pending = true;
                });
            };

            $scope.disableAccount = function(row) {
                var modalInstance = $modal.open({
                    templateUrl: 'ConfirmAccountDeleteCtrl.html',
                    controller: 'ConfirmAccountDeleteCtrl',
                    resolve: {
                        accountToDelete: function () {
                            return row;
                        },
                        accountList: function () {
                            return $scope.accountList;
                        }
                    }
                });
                modalInstance.result.then(function () {
                    $scope.loadAccounts();
                });
            };

            $scope.editAccount = function(row) {
                var modalInstance = $modal.open({
                    templateUrl: 'EditAccountCtrl.html',
                    controller: 'EditAccountDialogCtrl',
                    size: 'lg',
                    backdrop: 'static',
                    resolve: {
                        accountRow: function () {
                            return row;
                        },
                        accountList: function () {
                            return $scope.accountList;
                        }
                    }
                });
                modalInstance.result.then(function() {
                    $scope.loadAccounts();
                }, function() {
                    $scope.loadAccounts();
                });
            };
        }
    ]);

angular.module('tcl').controller('EditAccountDialogCtrl', ['$scope', '$modalInstance', '$resource', 'accountRow', 'accountList',
    function ($scope, $modalInstance, $resource, accountRow, accountList) {
            var AdminCredentials = $resource('api/accounts/:id/admin-credentials', {id:'@id'});

            $scope.accountList = accountList;
            $scope.accountpwd = {};
            $scope.account = angular.copy(accountRow);
            $scope.accountOrig = angular.copy($scope.account);
            $scope.msg = null;
            $scope.credentialErrors = {
                duplicateUsername: 'That username is already in use.',
                duplicateEmail: 'That email is already in use.',
                invalidUsername: 'Username must be 4 to 50 characters.',
                emptyEmail: 'Enter a valid email address.',
                invalidPassword: 'Enter a password that meets the requirements.',
                passwordRequired: 'A new password is required when you change the username.',
                badAccount: 'That account could not be found.'
            };

            $scope.closeEditAccount = function() {
                $modalInstance.close();
            };

            $scope.usernameChanged = function() {
                return $scope.account && $scope.accountOrig
                    && $scope.account.username !== $scope.accountOrig.username;
            };

            $scope.passwordRequired = function() {
                return $scope.usernameChanged()
                    || !!($scope.accountpwd && $scope.accountpwd.newPassword)
                    || !!($scope.accountpwd && $scope.accountpwd.newPasswordConfirm);
            };

            $scope.syncAccountRow = function(changes) {
                if (!$scope.accountList || !$scope.account) {
                    return;
                }
                angular.forEach($scope.accountList, function(item) {
                    if (item.id === $scope.account.id) {
                        angular.extend(item, changes);
                    }
                });
            };

            $scope.saveAccount = function() {
                var req = new AdminCredentials();
                req.id = $scope.account.id;
                req.newUsername = $scope.account.username;
                req.email = $scope.account.email;
                if ($scope.accountpwd.newPassword) {
                    req.newPassword = $scope.accountpwd.newPassword;
                }
                req.$save().then(function(result) {
                    var payload = angular.fromJson(result);
                    $scope.msg = {
                        type: payload.type,
                        text: payload.type === 'danger'
                            ? ($scope.credentialErrors[payload.text] || 'The account could not be updated.')
                            : 'Account updated.'
                    };
                    if (payload.type === 'danger') {
                        return;
                    }
                    $scope.syncAccountRow({
                        username: $scope.account.username,
                        email: $scope.account.email
                    });
                    $scope.accountOrig = angular.copy($scope.account);
                    $scope.accountpwd = {};
                }, function() {
                    $scope.msg = {type: 'danger', text: 'The account could not be updated.'};
                });
            };
    }
]);



angular.module('tcl').controller('ConfirmAccountDeleteCtrl', function ($scope, $modalInstance, accountToDelete,accountList,Account) {

    $scope.accountToDelete = accountToDelete;
    $scope.accountList = accountList;
    $scope.delete = function () {
        //console.log('Delete for', $scope.accountList[rowIndex]);
        Account.remove({id:accountToDelete.id},
            function() {
                var rowIndex = -1;
                angular.forEach($scope.accountList, function(item, idx) {
                    if (item.id === accountToDelete.id) {
                        rowIndex = idx;
                    }
                });
                if (rowIndex !== -1) {
                    $scope.accountList.splice(rowIndex, 1);
                }
                $modalInstance.close($scope.accountToDelete);
            },
            function() {
//                            console.log('There was an error deleting the account');
            }
        );
    };

    $scope.cancel = function () {
        $modalInstance.dismiss('cancel');
    };
});





