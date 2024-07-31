function [ time ] = mrLoadLogTime( filename )
    fid = fopen( filename );

    idx = 0;
    
    % Obtain the execution time for each frame (4th column and 4 lines per frame)
    time = [];
    while ~feof(fid)
        line = fgetl(fid);
        if ~isempty(line) && mod(idx,5) == 0
            data = str2num(line);
            time = [time; data(4)];
        end
        idx = idx + 1;
    end

    % Compute the average execution time
    time = mean(time);
    
end
