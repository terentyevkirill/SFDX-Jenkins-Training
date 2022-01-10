public class EinsteinVision_Admin {

    public static final Integer EPOCHS = 0;
    public static final Decimal LEARNING_RATE = 0;
    public static final String TRAIN_PARAMS = '';
    // public static final String TRAIN_PARAMS = JSON.serialize(
    //     new Map<String, Object>{
    //         'trainSplitRation' => 0.9,
    //         'withFeedback' => true
    //     }
    // );

    @AuraEnabled
    public static void createDatasetFromUrl(String zipUrl) {
        EinsteinVision_PredictionService service = new EinsteinVision_PredictionService();
        service.createDatasetFromUrlAsync(zipUrl);
    }
    @AuraEnabled
    public static List<EinsteinVision_Dataset> getDatasets() {
        EinsteinVision_PredictionService service = new EinsteinVision_PredictionService();
        EinsteinVision_Dataset[] datasets = service.getDatasets();
        return datasets;
    }
    @AuraEnabled
    public static String trainDataset(Decimal datasetId) {
        EinsteinVision_PredictionService service = new EinsteinVision_PredictionService();
        EinsteinVision_Model model = service.trainDataset(Long.valueOf(String.valueOf(datasetId)), 'Training', EPOCHS, LEARNING_RATE, TRAIN_PARAMS);
        return model.modelId;
    }
    @AuraEnabled
    public static void deleteDataset(Long datasetId) {
        EinsteinVision_PredictionService service = new EinsteinVision_PredictionService();
        service.deleteDataset(datasetId);
    }
    @AuraEnabled
    public static List<EinsteinVision_Model> getModels(Long datasetId) {
        EinsteinVision_PredictionService service = new EinsteinVision_PredictionService();
        EinsteinVision_Model[] models = service.getModels(datasetId);
        System.debug('models: ' + models);
        return models;
    }
    @AuraEnabled
    public static String getCatPrediction(Id catId, String fileName, String base64) {
        Blob fileBlob = EncodingUtil.base64Decode(base64);
        EinsteinVision_PredictionService service = new EinsteinVision_PredictionService();
        EinsteinVision_Dataset[] datasets = service.getDatasets();
        String breed;
        for (EinsteinVision_Dataset dataset : datasets) {
            if (dataset.Name.equals('Cats')) {
                EinsteinVision_Model[] models = service.getModels(dataset);
                EinsteinVision_Model model = models.get(0);
                EinsteinVision_PredictionResult result = service.predictBlob(model.modelId, fileBlob, '');
                EinsteinVision_Probability probability = result.probabilities.get(0);
                breed = probability.label;
                Cat__c cat = [SELECT Id FROM Cat__C WHERE Id=:catId];
                cat.Cat_Breed__c = breed;
                update cat;
                Attachment[] attsOld = [SELECT Id FROM Attachment WHERE ParentId=:catId];
                delete attsOld;
                Attachment att = new Attachment();
                att.Body = fileBlob;
                att.ParentId = cat.Id;
                att.Name = fileName;
                insert att;
            }
        }
        return breed;
    }
    @AuraEnabled
    public static List<EinsteinVision_Label> getCatLabels() {
        EinsteinVision_PredictionService service = new EinsteinVision_PredictionService();
        EinsteinVision_Dataset[] datasets = service.getDatasets();
        for (EinsteinVision_Dataset dataset : datasets) {
            if (dataset.Name.equals('Cats')) {
                return dataset.labelSummary.labels;
            }
        }
        return null;
    }
    @AuraEnabled
    public static String getImageUrlFromAttachment(Id catId) {
        List<Attachment> atts = [SELECT Id FROM Attachment WHERE ParentId=:catId];
        if (atts.size()>0) {
            return atts.get(0).Id;
        }
        return '';
    }
}