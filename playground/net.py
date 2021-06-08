# -*- coding: UTF-8 -*-
import MNN
F = MNN.expr
nn = MNN.nn

class MNNNet(nn.Module):
    '''
    create a mnn net with inference process
    '''
    def __init__(self, 
                 pretrain_model, 
                 input_layer_names=list(),
                 output_layer_names=list()):
        super(MNNNet, self).__init__()
        var_map = F.load_as_dict(pretrain_model)
        self.input_dicts, self.output_dicts = F.get_inputs_and_outputs(var_map)
        input_vars = []
        output_vars = []

        if len(output_layer_names) != 0:
            self.output_dicts = dict()
            for name in output_layer_names:
                self.output_dicts[name] = var_map[name]
        if len(input_layer_names) != 0:
            self.input_dicts = dict()
            for name in input_layer_names:
                self.input_dicts[name] = var_map[name]

        for name in self.input_dicts.keys():
            input_vars.append(var_map[name])
        for name in self.output_dicts.keys():
            output_vars.append(var_map[name])
            
        input_layer_names = list(self.input_dicts.keys())
        output_layer_names = list(self.output_dicts.keys())

        #dynamic calculation method
        #self.net = nn.load_module(input_vars, output_vars, False)

        #static calculation method
        self.net = nn.load_module_from_file(pretrain_model, input_layer_names, output_layer_names)

    def forward(self, x):
        x = self.net.forward(x)
        return x

    def get_net_input_output(self):
        return (self.input_dicts, self.output_dicts)

if __name__ == '__main__':
    import sys
    net = Net(sys.argv[1])
    input_dicts,output_dicts = net.get_net_input_output()
    for key in input_dicts.keys():
        print('key is {}, format is{}'.format(key, type(input_dicts[key].data_format)))
    for key in output_dicts.keys():
        print('key is {}, format is{}'.format(key, output_dicts[key].data_format))
