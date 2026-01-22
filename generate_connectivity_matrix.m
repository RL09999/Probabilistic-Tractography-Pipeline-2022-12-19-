%% Generate Probabilistic Connectivity Matrix
% -------------------------------------------------------------------------
% Script Name: generate_connectivity_matrix.m
% Description: This script processes the output from FSL probtrackx2 to 
%              construct a 90x90 probabilistic connectivity matrix based 
%              on the AAL atlas.
% Author     : Jieru Liao (Ruby)
% Date       : 2026-01-22
% -------------------------------------------------------------------------

clear; clc;

% Initialize matrices for 90 AAL regions
num_regions = 90;
seed_Voxel_matrix = zeros(num_regions, num_regions);
target_meanFDT_matrix = zeros(num_regions, num_regions);
target_Voxel_matrix = zeros(num_regions, num_regions);

% Path configuration (Update these paths as needed)
base_dir = './sub001/';

fprintf('Starting matrix construction...\n');

% Loop through each seed region
for i = 1:num_regions
    seed_name = sprintf('seed%03d', i);
    result_dir = fullfile(base_dir, sprintf('DTI.probtrackx2.%s', seed_name));
    
    % Check if the directory exists before loading
    if isfolder(result_dir)
        % Load seed voxel count
        seed_data = load(fullfile(result_dir, 'seed_Voxel_matrix.txt'));
        seed_Voxel_matrix(i, :) = seed_data(1);
        
        % Load target FDT and voxel data
        target_data = load(fullfile(result_dir, 'target_meanFDT_matrix.target_Voxel_matrix.txt'));
        target_meanFDT_matrix(i, :) = target_data(:, 1);
        target_Voxel_matrix(i, :) = target_data(:, 2);
    else
        warning('Results for %s not found in %s', seed_name, result_dir);
    end
end

% --- Matrix Calculation ---
% Formula: (Target_Voxels * Mean_FDT) / (Seed_Voxels * Number_of_Samples)
% Note: 10000 is the normalization factor based on tracking samples
ProbabilisticMatrix = (target_Voxel_matrix .* target_meanFDT_matrix) ./ (seed_Voxel_matrix .* 10000);

% Clean the matrix: Replace NaNs with 0 and set diagonal (self-connections) to 0
ProbabilisticMatrix(isnan(ProbabilisticMatrix)) = 0;
ProbabilisticMatrix(logical(eye(num_regions))) = 0;

% Save the final result
save('ProbabilisticMatrix.txt', 'ProbabilisticMatrix', '-ascii');

fprintf('Matrix generation complete. Saved as ProbabilisticMatrix.txt\n');
fprintf('Note: The matrix is asymmetric (Rows = Seeds, Columns = Targets).\n');

%% --- Optional: Visualize the Matrix ---
figure;
imagesc(ProbabilisticMatrix);
colorbar;
colormap('hot');
title('DTI Probabilistic Connectivity Matrix (AAL 90)');
xlabel('Target Regions');
ylabel('Seed Regions');
axis square;
