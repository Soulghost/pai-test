import argparse
import numpy as np
from cores.model import RecModel
import logging

logging.basicConfig(level = logging.INFO)

parser = argparse.ArgumentParser(description='Process some params.')
parser.add_argument('--pretrain_model', type=str, required=True,
                    help='Location of model')
parser.add_argument('--last_fixed_layer_name', type=str, 
                    help='Name of last fixed layer')
parser.add_argument('--input_layer_name', type=str, default="input",
                    help='Name of net input layer')
parser.add_argument('--data_dir', type=str, default="",
                    help='Path to get training data')
parser.add_argument('--train_label', type=str, default="",
                    help='Path to get training label')
parser.add_argument('--val_data_path', type=str, default="",
                    help='path to get validation data')
parser.add_argument('--test_data_path', type=str, default="",
                    help='Path to get test data')
parser.add_argument('--test_label', type=str, default="",
                    help='Path to get test label')
parser.add_argument('--class_number', type=int, default=4,
                    help='Number of classes in training task')
parser.add_argument('--epoch', type=int, default=10,
                    help='Number of epoch for training')
parser.add_argument('--snapshot_every_n_epochs', type=int, default=10,
                    help='Snapshot every n epochs')
parser.add_argument('--log_number', type=int, default=120,
                    help='Number of number to log training infos')
parser.add_argument('--model_type', type=str, default='mobilenetv3',
                    help='model type for classification task')
parser.add_argument('--save_path', type=str, default='./saved_model.mnn',
                    help='path to save snapshot')

args = parser.parse_args()

def train():
    '''
    training and validation process for finetune a model
    '''
    logging.info('start init model process:')
    model = RecModel(pretrain_model=args.pretrain_model, 
                     data_dir=args.data_dir,
                     epoch=args.epoch, 
                     last_fixed_layer_name=args.last_fixed_layer_name,
                     input_layer_name=args.input_layer_name,
                     model_type=args.model_type,
                     save_model_path=args.save_path,
                     snapshot_interval=args.snapshot_every_n_epochs)

    logging.info('start to convert dataset:')
    model.convert_dataset()

    logging.basicConfig(level = logging.INFO)

    logging.info('start train process:')
    model.train_func()

    logging.info('start predict process:')
    #results = model.predict(args.test_data_path)
    #for item in results:
    #    logging.info('the label of {} is {}'.format(item, np.argmax(np.array(results[item]))))

if __name__ == '__main__':
    train()

