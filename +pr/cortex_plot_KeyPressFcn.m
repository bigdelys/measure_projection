function cortex_plot_KeyPressFcn(handle, eventdata)

brainSide = eventdata.Character;

pr.show_or_hide_cortex_hemisphere(brainSide);

end
