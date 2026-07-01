package view;

import model.Arena2DModel;

public interface Arena2DView {

    /** Get model used by the view */
    Arena2DModel getModel();

    /** Notify view that model state has changed */
    void notifyModelChanged();
}
