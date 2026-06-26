package view;

import model.Arena2DModel;

public interface Arena2DView {

    Arena2DModel getModel();

    void notifyModelChanged();
}
