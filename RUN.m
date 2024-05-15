%% set paths 
clear all; close all; clc
currentPath=mfilename('fullpath');
currentPath=currentPath(1:strfind(currentPath, mfilename)-1);
addpath(genpath(currentPath)); cd(currentPath)
eeglab
close all


run('MAIN_GUI.mlapp')   