# -*- coding: UTF-8 -*-
import MNN
import os
import cv2
import numpy as np
from cores.WBReporter import WBReporter
from cores.net import Net
import json
F = MNN.expr
nn = MNN.nn

#for mnn model forward,including preprocess and postprocess
def mnn_image_predict(image_path, 
                      image_size, 
                      label_map_dict,
                      net):
    results = list()
    orin_image_data = cv2.imread(image_path)
    if orin_image_data is not None:
        image_data = cv2.cvtColor(orin_image_data, cv2.COLOR_BGR2RGB)
        image_data = cv2.resize(image_data, (image_size, image_size))
        image_height, image_width, _ = orin_image_data.shape
        normalized_image_data = (2.0 / 255.0) * image_data - 1.0
        input_data = F.placeholder([1, image_size, image_size, 3], F.NHWC, F.float)
        input_data.write(normalized_image_data.tolist())
        input_data = F.convert(input_data, F.NC4HW4)
        outputs = net.forward([input_data])[0]
        output_data = outputs.read()
        #if use np.array, would get unexpected result
        #predict_result[image_lists[i]] = output_data
        output_data = np.array(output_data.flatten().tolist())
        scores = np.max(output_data)
        class_name = label_map_dict[np.argmax(output_data)]
        return [class_name, scores]

def load_net(model_path, 
            output_layer_name,
            input_layer_name): 
    var_map = F.load_as_dict(model_path)
    input_var = var_map[input_layer_name]
    output_var = var_map[output_layer_name]
    return nn.load_module([input_var], [output_var], False)

if __name__ == '__main__':
    model_path = MNNGlobalVars['modelPath']
    label_json = os.path.join(model_path[:-4], 'MNNModelCache') + '/label_map.json'
    image_paths = list() 
    single_path = MNNGlobalVars.get('filePath')
    path_list = MNNGlobalVars.get('filePaths')
    if path_list is not None and len(path_list) > 0:
        image_paths = path_list
    elif single_path is not None:
        image_paths.append(single_path)

    #start predict process
    WBReporter.WBProcessStartReport()
    output_layer_names = 'prob'
    input_layer_name = 'input'

    #init net
    net = load_net(model_path, 
                   output_layer_names, 
                   input_layer_name)
    class_index_dict = {}
    with open(label_json, 'r') as fp:
        class_index_dict = json.load(fp)
    if bool(class_index_dict):
        label_map_dict = {}
        for key in class_index_dict.keys():
            label_map_dict[class_index_dict[key]] = key
        image_size = 224
        total_image_number = len(image_paths)
        for i,image in enumerate(image_paths):
            #start to predict
            results = mnn_image_predict(image,
                                        image_size,
                                        label_map_dict,
                                        net)
            #log out predict process infos
            WBReporter.reportPredictStatus(results, image, i, total_image_number)
    #report end of predict process
    WBReporter.WBProcessEndReport()
        
