package env;

import java.util.Set;
import java.util.stream.Collectors;

public interface Arena2DView {
    Arena2DModel getModel();
    void notifyModelChanged();
}
