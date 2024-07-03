function item = lookupdm3tag(name, node)
    %Utility function for looking up nodes in a
    %tree by full name.
    %tree levels delimited by '.'

    %node names are separated by dots.
    %get list of tokens
    item = [];
    tokens = strread(name, '%s', 'delimiter', '.');
    numtokens = length(tokens);
    
    for i = 1:numtokens
        for j = 1:length(node)
            token = tokens(i);
            nodename = node(j).name;
            if strcmp(token, nodename)
                %get next node, carry on lookup
                node = node(j).child;
                if i == numtokens
                    %our last token has matched - item found
                    item = node;
                    return;
                end
                break;
            end
        end
    end
end
