function [neuron,del_ids_location]= manually_remove_neurons(neuron)

            data= neuron.A;
            ncell= size(data,2); % reset
            % plot neuron numbers
            neuron.show_contours;
            for icell= 1:ncell
                I= full(reshape( data(:,icell), [ size(neuron.Cn,1) size(neuron.Cn,2) ] )); % get neuron shape


                [out1,out2]= find(I==max(I,[],'all')); % find maximum intensity: center position of neuron
                plot(round(mean(out2)),round(mean(out1)),'.','MarkerSize',10,'color','c'); % dot icell center
                text(round(mean(out2))-2,round(mean(out1)),num2str(icell),'color','k','fontsize',12); % indicate neuron number
                title([num2str(ncell) ' neurons'],'fontsize', 12)
            end
            axis tight, truesize([850 850])
            % ask user to choose neurons
            prompt = '\nENTER NEURONS TO DELETE e.g. [10 56 8]:\n';
            del_ids_location= input(prompt);
            % apply deletion
            del_ids= unique(del_ids_location);
            % update neuron
            neuron.A(:,del_ids)=[];
            neuron.C(del_ids,:)=[];
            neuron.C_raw(del_ids,:)=[];
            neuron.S(del_ids,:)=[];
            neuron.ids(del_ids)=[];
            neuron.Coor(del_ids)=[];
            fprintf(['\n' num2str(length(del_ids)) ' deleted neurons, ' num2str(length(neuron.ids)) ' remaining\n'])
            close(gcf)
        