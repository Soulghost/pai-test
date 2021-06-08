import numpy as np
from cores.model import RecModel
from cores.WBReporter import WBReporter
import logging

MNNGlobalVars = {}
MNNGlobalVars["epoch"] = 5
MNNGlobalVars["quant"] = True
MNNGlobalVars["savePath"] = "/root/models"
MNNGlobalVars["trainDatasetPath"] = "/root/ImageClassifier"
MNNGlobalVars["sessionName"] = "476a4f577ea84fa1a77fbf601d815bcc"

def train():
    '''
    training and validation process for finetune a model
    '''
    #LocalGlobalVars = {
    #        'pretrain_model': "./pretrain_model/mb3.mnn",
    #        'last_fixed_layer_name': "MobilenetV3/expanded_conv_14/add",
    #        'input_layer_name': "input",
    #         'snapshot_every_n_epochs': 5,
    #         'model_type': 'mobilenetv3'
    #        }
    LocalGlobalVars = {
            'pretrain_model': "./pretrain_model/mb3_small.mnn",
            'last_fixed_layer_name': "MobilenetV3/expanded_conv_10/add",
            'input_layer_name': "input",
             'snapshot_every_n_epochs': 5,
             'model_type': 'mobilenetv3_small'
            }
    logging.info('start init model process:')

    if 'trainDatasetPath' in MNNGlobalVars and 'savePath' in MNNGlobalVars:
        epoch = 0
        if 'epoch' in MNNGlobalVars:
            epoch = int(MNNGlobalVars['epoch'])
        is_quantize = True
        if 'quant' in MNNGlobalVars:
            is_quantize = MNNGlobalVars['quant']
        #report train process start
        WBReporter.WBProcessStartReport()
        model = RecModel(pretrain_model=LocalGlobalVars['pretrain_model'], 
                         data_dir=MNNGlobalVars['trainDatasetPath'],
                         epoch=epoch,
                         last_fixed_layer_name=LocalGlobalVars['last_fixed_layer_name'],
                         input_layer_name=LocalGlobalVars['input_layer_name'],
                         model_type=LocalGlobalVars['model_type'],
                         save_model_path=MNNGlobalVars['savePath'],
                         snapshot_interval=LocalGlobalVars['snapshot_every_n_epochs'],
                         is_quantize=is_quantize)

        logging.info('start to convert dataset:')
        model.convert_dataset()
        WBReporter.reportDataConvertStatus()

        logging.basicConfig(level = logging.INFO)

        logging.info('start train process:')
        model.train_func()

    #report end of train process
    WBReporter.WBProcessEndReport()

if __name__ == '__main__':
    train()

