import os
import pandas as pd
import matplotlib.pyplot as plt
import glob
src_folder = '/home/ndc/repos/'
os.chdir(src_folder+'DistributedMachineLearningThesis/partial_results')


data_size = ["1000", "16000","32000","64000","*"]
num_nodes = ["8","16","*"]
seeds = ["1111", "2222", "3333", "4444", "5555", "6666", "7777", "8888", "9999", "1234","*"]
function = ["f1","f2","*"]
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
        return os.getcwd()+'/'+folder+'/containers.csv'

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
                if len(df) == 0:
                        return False
                df = df[['MEM%','CPU%','NETI/O','BLOCKI/O']]
                return df
        except:
                return False



def removepercent(x):
        return x.replace("%",'')



#Converts strings like '30 bytes' or '25Kb' to it's integer equivalente in megabytes
def stringtoMbyte(_inputstring):
        inputstring = _inputstring.upper()
        multiplier = 1
        if 'GB' in inputstring:
                multiplier = 1024
                inputstring=inputstring.replace('GB','')
        elif 'MB' in inputstring:
                multiplier = 1
                inputstring=inputstring.replace('MB','')
        elif 'KB' in inputstring:
                multiplier = 1/1024
                inputstring=inputstring.replace('KB','')
        elif 'B' in inputstring:
                multiplier = 1/(1024 * 1024)
                inputstring=inputstring.replace('B','')
                
        return round(float(inputstring) * multiplier,4)


#Converts strings like '30 bytes' or '25Kb' to it's integer equivalente in megabytes
def stringPercentToFloat(_inputstring):
        inputstring = _inputstring.upper()
        output = inputstring.replace("%",'')
        return float(output)



def splitColumn(dataframe,column):
        col = list(map(stringtoMbyte,dataframe[column]))
        df = pd.DataFrame(col)
        df.columns = [column]
        return df[column]

def chopPercentage(dataframe,column):
        col = list(map(stringPercentToFloat,dataframe[column]))
        df = pd.DataFrame(col)
        df.columns = [column]
        return df[column]








def create_plot(dataframes,ylabel,xlabels):       

        fig = plt.figure(1, figsize=(9, 6))
        ax = fig.add_subplot(111)       
        
        
        bp = ax.boxplot(dataframes,labels=xlabels,patch_artist=True)        
        #ax.legend(xlabels,markerscale=0, handlelength=0)

        ax.yaxis.grid(True, linestyle='-', which='major', color='lightgrey', alpha=0.5)
        ax.xaxis.grid(True, linestyle='-', which='major', color='lightgrey', alpha=0.5)               

        ax.set_ylabel(ylabel,fontsize=18)      
        


        body_color = '#b3b6ba'
        lines_color = '#5c5959'
        ## change outline color, fill color and linewidth of the boxes
        for box in bp['boxes']:
                # change outline color
                box.set( color=lines_color, linewidth=1)
                # change fill color
                box.set( facecolor = body_color )

        ## change color and linewidth of the whiskers
        for whisker in bp['whiskers']:
                whisker.set(color=body_color, linewidth=2)

        ## change color and linewidth of the caps
        for cap in bp['caps']:
                cap.set(color=body_color, linewidth=1)

        ## change color and linewidth of the medians
        for median in bp['medians']:
                median.set(color=lines_color, linewidth=1)

        ## change the style of fliers and their fill
        for flier in bp['fliers']:
                flier.set(marker='o', color=body_color, alpha=0.5)

        
        #filename = title+'.png'
        #filename = filename.replace('*','[ALL]')
        return fig



memcpu_dir = "/home/ndc/repos/DistributedMachineLearningThesis/plots/containers/mem_cpu/"
netio_dir = "/home/ndc/repos/DistributedMachineLearningThesis/plots/containers/net_io/"
disk_dir = "/home/ndc/repos/DistributedMachineLearningThesis/plots/containers/disk/"


def save_plot(fig,destpath,current_pattern):
        if type(fig) != bool:                        
                        filename = current_pattern[0:len(current_pattern)-1]+'-summary'                                             
                        filename = filename.replace('*','[ALL]')+'.png'
                        print(destpath+filename)                   
                        fig.savefig(destpath+filename, bbox_inches='tight',dpi=640)


for current_pattern in patterns:
        if current_pattern != False:
                print(current_pattern)
                df = create_table(current_pattern)
                if type(df) != bool:
                        cpu = chopPercentage(df,'CPU%')



                        mem = chopPercentage(df,'MEM%')
                        memcpu_fig = create_plot([mem,cpu],'Percentage (%) \n Total memory: 2048MB',["MEM","CPU"])
                        save_plot(memcpu_fig,memcpu_dir,current_pattern)                
                        plt.cla()
                        

                        net = df['NETI/O'].str.split("/",expand=True)
                        net.columns = ['INPUT','OUTPUT']
                        net_input = splitColumn(net,'INPUT')
                        net_output = splitColumn(net,'OUTPUT')
                        net_fig = create_plot([net_input,net_output],'Megabytes',["Download","Upload"])
                        save_plot(net_fig,netio_dir,current_pattern)     
                        plt.cla()           

                        disk = df['BLOCKI/O'].str.split("/",expand=True)
                        disk.columns = ['INPUT','OUTPUT']
                        disk_input = splitColumn(disk,'INPUT')
                        disk_output = splitColumn(disk,'OUTPUT')
                        disk_fig = create_plot([disk_input,disk_output],'Megabytes',["Read","Write"])
                        save_plot(disk_fig,disk_dir,current_pattern)
                        plt.cla()
               
                
                
                


