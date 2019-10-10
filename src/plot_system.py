import os
import pandas as pd
import matplotlib.pyplot as plt
import glob
os.chdir("/home/ndc/repos/DistributedMachineLearningThesis/partial_results")


data_size = ["1000", "16000","32000","64000","*"]
num_nodes = ["8","16","*"]
seeds = ["1111", "2222", "3333", "4444", "5555", "6666", "7777", "8888", "9999", "1234","*"]
function = ["f1"]
num_neighboors = ["2","4","*"]


#Generate the file pattern name to be used by glob.glob on the nested loop below
def makename(_num_nodes,_data_size,_function,_seed,_num_neighboors):
        dim_functions = {"f1":"2","f2":"3","f4":"5","*":"*"}
        name = _num_nodes + '-'+ _data_size + '-' + _function + '-' + _seed + '-' + _num_neighboors +'-'+dim_functions[_function]+'*'
        return name    

patterns = []
for _data_size in data_size:
        for _num_nodes in num_nodes:
                for _seeds in seeds:
                        for _function in function:
                                for _num_neighboors in num_neighboors:
                                        
                                        current_pattern = makename(_num_nodes,_data_size,_function,_seeds,_num_neighboors)
                                        patterns.append(current_pattern)
                                        

def create_path(folder):
        return os.getcwd()+'/'+folder+'/system.csv'

#It merges the many dataframes (one for each csv) in a single dataframe
def create_table(pattern):        
        folders = glob.glob(pattern)        
        dfs = []
        df = -1        
        for folder in folders:                
                path = create_path(folder)
                dfs.append(pd.read_csv(path))              
        try:
                        df = pd.concat(dfs)                        
                        df = df.drop(['MAPE', 'MSE','R2'], axis=1)                        
                        df.columns = ['calculate_maxmin','clustering_time','elapsed_time','create_histogram','testing_model','train_global_model','local_training']  
                        df =  df[['local_training','calculate_maxmin','clustering_time','create_histogram','testing_model','train_global_model','elapsed_time']]                                                                        
        except:
                return False
                
        if len(df) == 0:
                return False
        return df


















def create_plot(pattern):
        df = create_table(pattern)

        if type(df) == bool:
                return False, False
        plt.cla()
        #Filtering7                
        local_training = df['local_training']
        calculate_maxmin = df['calculate_maxmin']
        clustering_time = df[(df.clustering_time > 0)]['clustering_time']
        create_histogram = df[(df.create_histogram > 0) ]['create_histogram']
        testing_model = df[(df.testing_model > 0)]['testing_model']
        train_global_model = df['train_global_model']
        elapsed_time = df[(df.elapsed_time > 0)]['elapsed_time']      

        fig = plt.figure(1, figsize=(9, 6))
        ax = fig.add_subplot(111)

        lbls = ['local_training','calculate_maxmin','clustering_time','create_histogram','testing_model','train_global_model','elapsed_time']
        bp = ax.boxplot([local_training,calculate_maxmin,clustering_time,create_histogram,testing_model,train_global_model,elapsed_time],labels=lbls,patch_artist=True)

        ax.yaxis.grid(True, linestyle='-', which='major', color='lightgrey', alpha=0.5)
        ax.xaxis.grid(True, linestyle='-', which='major', color='lightgrey', alpha=0.5)               

        ax.set_ylabel('Seconds',fontsize=18)
        title = pattern[0:len(pattern)-1]+'-summary'
        plt.title(title.replace('*','[ALL]'),fontsize = 20)


        body_color = '#b3b6ba'
        lines_color = '#5c5959'
        ## change outline color, fill color and linewidth of the boxes
        for box in bp['boxes']:
                # change outline color
                box.set( color=lines_color, linewidth=2)
                # change fill color
                box.set( facecolor = body_color )

        ## change color and linewidth of the whiskers
        for whisker in bp['whiskers']:
                whisker.set(color=body_color, linewidth=2)

        ## change color and linewidth of the caps
        for cap in bp['caps']:
                cap.set(color=body_color, linewidth=2)

        ## change color and linewidth of the medians
        for median in bp['medians']:
                median.set(color=lines_color, linewidth=2)

        ## change the style of fliers and their fill
        for flier in bp['fliers']:
                flier.set(marker='o', color=body_color, alpha=0.5)

        
        filename = title+'.png'
        filename = filename.replace('*','[ALL]')
        return fig,filename


current_pattern = patterns[0]
for current_pattern in patterns:
        if current_pattern != False:        
                fig,filename = create_plot(current_pattern)
                if type(fig) != bool:
                        output_folder = '/home/ndc/repos/DistributedMachineLearningThesis/plots/system/'
                        fig.savefig(output_folder+filename, bbox_inches='tight')


