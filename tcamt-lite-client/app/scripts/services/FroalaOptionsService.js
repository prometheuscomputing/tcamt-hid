/**
 * Builds Froala editor options from server-provided AppInfo (including froalaKey).
 */
angular.module('tcl').factory('FroalaOptionsService', function () {

    function buildEvents($rootScope) {
        return {
            'froalaEditor.initialized': function () {
            },
            'froalaEditor.file.error': function (e, editor, error) {
                $rootScope.msg().text = error.text;
                $rootScope.msg().type = error.type;
                $rootScope.msg().show = true;
            },
            'froalaEditor.image.error ': function (e, editor, error) {
                $rootScope.msg().text = error.text;
                $rootScope.msg().type = error.type;
                $rootScope.msg().show = true;
            }
        };
    }

    return {
        build: function (appInfo, $rootScope, extras) {
            var uploadedImagesUrl = (appInfo && appInfo.uploadedImagesUrl) ? appInfo.uploadedImagesUrl : '';
            var options = {
                placeholderText: '',
                imageUploadURL: uploadedImagesUrl + '/upload',
                imageAllowedTypes: ['jpeg', 'jpg', 'png', 'gif'],
                fileUploadURL: uploadedImagesUrl + '/upload',
                fileAllowedTypes: ['application/pdf', 'application/msword', 'application/x-pdf', 'text/plain', 'application/xml', 'text/xml'],
                charCounterCount: false,
                quickInsertTags: [''],
                immediateAngularModelUpdate: true,
                events: buildEvents($rootScope),
                key: (appInfo && appInfo.froalaKey) ? appInfo.froalaKey : '',
                imageResize: true,
                imageEditButtons: ['imageReplace', 'imageAlign', 'imageRemove', '|', 'imageLink', 'linkOpen', 'linkEdit', 'linkRemove', '-', 'imageAlt'],
                pastePlain: true
            };
            if (extras) {
                angular.extend(options, extras);
            }
            return options;
        }
    };
});
