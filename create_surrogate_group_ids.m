function surrogateGroupIds = create_surrogate_group_ids(groupId, numberOfPermutations, subjectId, allowRepetitionInPermutation)
% subjectId has to be the same lenght vecotr as groupId and each subject only can belong to one
% group. 
%
% surrogateGroupIds = create_surrogate_group_ids(groupId, numberOfPermutations, subjectId, allowRepetitionInPermutation)
%
% Output
% surrogateGroupIds may contain zeros when subjectId is provided. These are unused (unassigned to any group) data points and
% should not be used in surrogate computations.

if nargin < 3
    subjectId = [];
end;

if nargin < 4
    allowRepetitionInPermutation = true;
end;

for i = 1:2
    numberOfGroupMembers(i) = sum(groupId == i);
end;

surrogateGroupIds = zeros(numberOfPermutations, length(groupId));

if ~isempty(subjectId)
    % find out what is the group ID for each subject         
    uniqeSubjectId = unique(subjectId);
    
    for i=1:length(uniqeSubjectId);
        % find all data points for each subject
        subjectDataPointId = find(subjectId == uniqeSubjectId(i));
        
        % make sure they all have the same group (otherwise throw an error)
        if length(unique(groupId(subjectDataPointId))) == 1
            subjectGroupId(uniqeSubjectId(i)) = groupId(subjectDataPointId(1));
        else
            error('Some subjects belong to more than one group!');
        end;
    end;    
    
    for i=1:2
        numberOfSubjectsInGroup(i) = sum(subjectGroupId(uniqeSubjectId) == i);
    end;
end;


for permutationNumber = 1:numberOfPermutations
    
    % if subjectIds are not provided, permute points, which allows selection of group points with
    % nore regard to their subejctId. 
    if isempty(subjectId)

        if allowRepetitionInPermutation
           
            % for the first group select the same number of members from all, allowing repetition
            surrogateGroup1MembersId = randi(length(groupId) , 1,numberOfGroupMembers(1));
            
            % for the second group, select the same number (allwing repition) from the remaining members
            remainingIds = setdiff(1:length(groupId), surrogateGroup1MembersId);
            surrogateGroup2MembersId = remainingIds(randi(length(remainingIds) , 1,numberOfGroupMembers(2)));
            
            surrogateGroupIds(permutationNumber, surrogateGroup1MembersId) = 1;
            surrogateGroupIds(permutationNumber, surrogateGroup2MembersId) = 2;
        else
            surrogateGroupIds = groupId(randperm(length(groupId)));
        end;
        
    else % when subjectIds are provided, permute group identity of subjects, instead of each IC
        
        % for the first group select some random subjects (allowing repetition) from all subjects
        surrogateGroup1SubjectId = randi(sum(numberOfSubjectsInGroup), 1, numberOfSubjectsInGroup(1));
        
        % for the second group, select the same number of subjects from the remaining subjects
        remainingIds = setdiff(1:sum(numberOfSubjectsInGroup), surrogateGroup1SubjectId);
        surrogateGroup2SubjectId = remainingIds(randi(length(remainingIds) , 1,numberOfSubjectsInGroup(2)));
        
        
        surrogateSubjectGroup = zeros(1, length(uniqeSubjectId));
        surrogateSubjectGroup(surrogateGroup1SubjectId) = 1;
        surrogateSubjectGroup(surrogateGroup2SubjectId) = 2;
        
        % assign subject group membership to its member data points (e.g. ICs)
        for i=1:length(uniqeSubjectId);
            % find all data points for each subject
            subjectDataPointId = find(subjectId == uniqeSubjectId(i));
            
            % assign subject surrogate group id to its associated data points
            surrogateGroupIds(permutationNumber, subjectDataPointId) = surrogateSubjectGroup(i);
        end;

    end;
end;